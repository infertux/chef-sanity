#!/bin/bash
# Tests the switch from ifupdown to systemd-networkd (recipes/network.rb), which Test Kitchen can't cover since
# systemd-networkd leaves alone the interfaces Docker configures: Debian 13 containers configured by ifupdown
# are plugged into a "LAN" network namespace, where dnsmasq is the DHCPv4 server and the IPv6 router, and
# sanity::network is converged on them with Cinc, like Test Kitchen does.
#
# Usage: sudo test/network/test.sh
# Requires Docker, iproute2, dnsmasq and python3. IPv6 is only tested when the kernel has it enabled,
# set REQUIRE_IPV6=1 to fail otherwise. Set CHEF_VERSION to test another Cinc version (default: 19).

# shellcheck disable=SC2016 # commands in single quotes are expanded in the nodes
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
work=$(mktemp -d)
name=sanity-network-test # prefix of the images, containers and network namespace
failures=0
converges=0
probes=()

cleanup() {
  local status=$?
  if [ $status -ne 0 ]; then
    for log in "$work"/*.log; do
      [ -e "$log" ] || continue # no logs yet, e.g. when an image fails to build
      echo "::group::$(basename "$log")"
      cat "$log"
      echo '::endgroup::'
    done
    for node in $(docker ps --format '{{.Names}}' --filter "name=$name-" | sed "s/^$name-//"); do
      echo "::group::state of $node at the end"
      state "$node"
      echo '::endgroup::'
    done
    [ ! -f "$work/results" ] || cat "$work/results" # again, after the logs
  fi
  [ ${#probes[@]} -eq 0 ] || kill "${probes[@]}" 2>/dev/null || true
  docker ps --all --quiet --filter "name=$name-" | xargs -r docker rm --force >/dev/null
  [ ! -f "$work/dnsmasq.pid" ] || kill "$(cat "$work/dnsmasq.pid")" 2>/dev/null || true
  ip netns del "$name" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

if [ -e /proc/sys/net/ipv6 ]; then
  ipv6=true
elif [ "${REQUIRE_IPV6:-0}" = 1 ]; then
  echo 'IPv6 is disabled in this kernel' >&2
  exit 1
else
  ipv6=false
  echo '⚠ IPv6 is disabled in this kernel: skipping IPv6 checks'
fi

## Helpers

# say MESSAGE: prints MESSAGE and adds it to the results
say() { echo "$1" | tee -a "$work/results"; }

# on NODE COMMAND: runs COMMAND in NODE
on() { docker exec "$name-$1" sh -c "$2"; }

# check DESCRIPTION COMMAND...: runs COMMAND and reports whether it succeeded
check() {
  local description=$1
  shift
  if "$@" >/dev/null 2>&1; then
    say "  ✔ $description"
  else
    say "  ✘ $description"
    failures=$((failures + 1))
  fi
}

# wait_for SECONDS COMMAND...: waits until COMMAND succeeds
wait_for() {
  local deadline=$((SECONDS + $1))
  shift
  until "$@" >/dev/null 2>&1; do
    [ $SECONDS -lt $deadline ] || return 1
    sleep 0.5
  done
}

# address NODE 4|6: NODE's global addresses on eth0
address() { on "$1" "ip -$2 -o addr show dev eth0 scope global -tentative | awk '{ print \$4 }'"; }
has_address() { [ -n "$(address "$1" "$2")" ]; }
same_address() { [ "$(address "$1" "$2")" = "$3" ]; }

# boot NODE IMAGE BRIDGE MAC: starts NODE, or restarts it to simulate a reboot, with eth0 plugged into BRIDGE
boot() {
  local node=$1 image=$2 bridge=$3 mac=$4 pid
  if docker inspect "$name-$node" >/dev/null 2>&1; then
    docker restart --time 30 "$name-$node" >/dev/null
  else
    docker run --detach --name "$name-$node" --hostname "$node" --privileged --cgroupns private \
      --network none --stop-signal SIGRTMIN+3 --volumes-from "$name-cinc" \
      --volume "$repo:/cookbooks/sanity:ro" --volume "$work:/work:ro" "$name:$image" >/dev/null
    docker exec -i "$name-$node" sh -c 'cat > /etc/network/interfaces' <"$work/$node.interfaces"
    docker exec -i "$name-$node" sh -c 'mkdir -p /etc/cinc && cat > /etc/cinc/client.rb' <"$work/client.rb"
  fi
  pid=$(docker inspect --format '{{.State.Pid}}' "$name-$node")
  ip -n "$name" link del "v-$node" 2>/dev/null || true
  ip -n "$name" link add "v-$node" type veth peer name eth0 address "$mac" netns "$pid"
  ip -n "$name" link set "v-$node" master "$bridge" up
  wait_for 60 booted "$node" || { echo "$node didn't boot" >&2; exit 1; }
  # containers skip udev's coldplug, which raises allow-hotplug interfaces and lets systemd-networkd manage them
  on "$node" 'systemctl start systemd-udevd && timeout 30 udevadm trigger --action=add --subsystem-match=net --settle'
}
booted() { on "$1" 'systemctl is-system-running || true' | grep -qxE 'running|degraded'; } # exits 1 when degraded

# state NODE: NODE's network state, to debug failures
state() {
  on "$1" 'ps -eo args | grep "^dhcpcd"; ip addr show dev eth0; ip -6 route show table all | grep -v "^local\|^multicast"
    networkctl status --no-pager eth0
    for key in disable_ipv6 accept_ra autoconf addr_gen_mode forwarding; do echo "eth0 $key: $(cat /proc/sys/net/ipv6/conf/eth0/$key)"; done
    journalctl --no-pager --boot --unit systemd-networkd | grep -iE "ndisc|router|gateway|route|lifetime" | tail -n 40' 2>&1 || true
}

# converge NODE [RUN_LIST]: converges NODE with Cinc, its output goes to $log
converge() {
  converges=$((converges + 1))
  printf -v log "%s/converge%02d-%s.log" "$work" "$converges" "$1"
  on "$1" "/opt/cinc/bin/cinc-client --local-mode --config /etc/cinc/client.rb --json-attributes /work/$1.json \
    --override-runlist '${2:-recipe[sanity::network]}' --no-color" >"$log" 2>&1
}
reconverged() { converge "$1" "${2:-}" && grep -q 'Infra Phase complete, 0/' "$log"; }

# probe NODE 4|6: keeps a TCP connection to NODE open, like an SSH session (see probe.py)
probe() {
  local port=700$2
  on "$1" "systemd-run --quiet --unit=echo$2 socat TCP$2-LISTEN:$port,reuseaddr,fork EXEC:cat"
  sleep 1
  ip netns exec "$name" python3 "$here/probe.py" "$(address "$1" "$2" | cut -d/ -f1)" "$port" "$work/$1.probe$2" &
  probes+=($!)
}
connected() { awk -v now="$(date +%s.%N)" '$1 != "DISCONNECTED" && now - $1 < 2 { ok = 1 } END { exit !ok }' "$1"; }

# survived NODE 4|6: checks the probe's connection is still alive
survived() {
  local status=$work/$1.probe$2
  wait_for 30 connected "$status" || true
  check "IPv$2 connection survived ($(awk '$1 == "DISCONNECTED" { print; next } { print "longest stall: " $2 "s" }' "$status"))" \
    connected "$status"
}

# settle: gives systemd-networkd time to get router advertisements and to probe routers, which can remove routes
settle() { if $ipv6; then sleep 10; fi; }

# networkd NODE IPV4: checks systemd-networkd alone configures NODE, with the same IPv4 address as before
networkd() {
  check 'systemd-networkd configured eth0' wait_for 30 on "$1" 'networkctl list --no-legend eth0 | grep -q " configured"'
  settle
  check 'no DHCP client from ifupdown left' on "$1" '! pgrep -x dhcpcd'
  check "same IPv4 address ($2)" wait_for 30 same_address "$1" 4 "$2"
  check 'IPv4 default route' on "$1" 'ip -4 route show default | grep -q .'
  if $ipv6; then
    check 'IPv6 address from router advertisements' has_address "$1" 6
    check 'IPv6 default route' on "$1" 'ip -6 route show default | grep -q .'
  fi
}

# no_public_ipv6 NODE: whether NODE has no IPv6 address or route beyond its link-local ones, which are fine
no_public_ipv6() { on "$1" '[ -z "$(ip -6 addr show dev eth0 scope global)" ] && [ -z "$(ip -6 route show default)" ]'; }
refused() { ! converge "$1" && grep -q 'Refusing to switch to systemd-networkd' "$log" && grep -qF "$2" "$log"; }

# interfaces FILE allow-hotplug|auto inet6|-: writes an ifupdown configuration like the one Debian's installer writes
interfaces() {
  printf 'source /etc/network/interfaces.d/*\n\nauto lo\niface lo inet loopback\n\n%s eth0\niface eth0 inet dhcp\n' "$2" \
    >"$work/$1.interfaces"
  if $ipv6 && [ "$3" = inet6 ]; then printf 'iface eth0 inet6 auto\n' >>"$work/$1.interfaces"; fi
}

## Setup

say '▶ Setting up'
docker build --quiet --target dhcpcd --tag "$name:dhcpcd" "$here" >/dev/null
docker create --name "$name-cinc" --volume /opt/cinc "cincproject/cinc:${CHEF_VERSION:-19}" true >/dev/null

# the network recipes don't use sanity's dependencies: stub them rather than fetching them from Supermarket
sed -nE "s/^depends '([^']+)'(, '[~>=< ]*([0-9.]+)')?.*/\1 \3/p" "$repo/metadata.rb" | while read -r cookbook version; do
  [[ $version =~ ^[0-9]+\.[0-9]+$ ]] && version=$version.0
  mkdir -p "$work/cookbooks/$cookbook"
  printf "name '%s'\nversion '%s'\n" "$cookbook" "${version:-0.0.0}" >"$work/cookbooks/$cookbook/metadata.rb"
done
printf "cookbook_path %%w(/cookbooks /work/cookbooks)\nchef_repo_path '/tmp/chef-repo'\n" >"$work/client.rb"

ip netns add "$name"
ip -n "$name" link set lo up
for bridge in br0 br1; do
  ip -n "$name" link add $bridge type bridge mcast_snooping 0
  ip -n "$name" link set $bridge up
done
ip -n "$name" addr add 10.99.0.1/24 dev br0 # LAN with a DHCPv4 server and an IPv6 router
ip -n "$name" addr add 10.98.0.1/24 dev br1 # LAN without, for static addresses
dnsmasq_ipv6=()
if $ipv6; then
  # forward like a real router, so that the kernel sets the router flag in its neighbor advertisements: systemd-networkd
  # removes the default route via a router whose advertisements don't have it (RFC 4861 7.2.5)
  ip netns exec "$name" sysctl -qw net.ipv6.conf.all.forwarding=1
  ip -n "$name" addr add fd00:99::1/64 dev br0 nodad
  # shellcheck disable=SC2054 # dnsmasq's option value has commas
  dnsmasq_ipv6=(--enable-ra --dhcp-range=fd00:99::,ra-only)
fi
ip netns exec "$name" dnsmasq --user=root --interface=br0 --bind-interfaces --port=0 --dhcp-authoritative \
  --dhcp-range=10.99.0.100,10.99.0.199,2m "${dnsmasq_ipv6[@]}" --dhcp-leasefile="$work/dnsmasq.leases" \
  --pid-file="$work/dnsmasq.pid" --log-facility="$work/dnsmasq.log"

## DHCP: switched to systemd-networkd without rebooting, keeping the same IPv4 address

# hotplug: an allow-hotplug interface (raised by ifup@eth0.service), as Debian's installer configures it
# auto: an auto interface (raised by networking.service)
interfaces hotplug allow-hotplug inet6
interfaces auto auto inet6
for node_mac in hotplug=02:00:00:00:00:01 auto=02:00:00:00:00:02; do
  node=${node_mac%=*} mac=${node_mac#*=}
  say "▶ DHCP, $node interface"
  echo '{}' >"$work/$node.json"
  boot "$node" dhcpcd br0 "$mac"
  wait_for 30 has_address "$node" 4 || { echo "ifupdown didn't configure IPv4" >&2; exit 1; }
  if $ipv6; then wait_for 30 has_address "$node" 6 || { echo "ifupdown didn't configure IPv6" >&2; exit 1; }; fi
  # dhcpcd's stable private IPv6 addresses (RFC 7217) can't be kept: systemd-networkd uses EUI-64 ones
  v4=$(address "$node" 4)
  probe "$node" 4
  state "$node" >"$work/state-before-$node.log"

  check 'converges' converge "$node"
  check '/etc/network/interfaces moved to /etc/network/interfaces.save' \
    on "$node" '[ ! -e /etc/network/interfaces ] && [ -e /etc/network/interfaces.save ]'
  check "ifupdown's units are stopped" on "$node" '! systemctl is-active --quiet networking.service ifup@eth0.service'
  networkd "$node" "$v4"
  state "$node" >"$work/state-after-switch-$node.log"
  survived "$node" 4
  check 'no failed units' on "$node" '[ -z "$(systemctl --failed --no-legend)" ]'
  check 'converges again without changes' reconverged "$node"

  say "▶ DHCP, $node interface, after a reboot"
  boot "$node" dhcpcd br0 "$mac"
  networkd "$node" "$v4"
  check 'no failed units' on "$node" '[ -z "$(systemctl --failed --no-legend)" ]'
done

## Static address: left to ifupdown

say '▶ Static address'
printf 'auto lo\niface lo inet loopback\n\nauto eth0\niface eth0 inet static\n\taddress 10.98.0.20/24\n\tgateway 10.98.0.1\n' \
  >"$work/static.interfaces"
echo '{}' >"$work/static.json"
boot static dhcpcd br1 02:00:00:00:00:10
check 'refuses to switch' refused static '/etc/network/interfaces uses inet static'
# same configuration, with eth0 in a file sourced from outside /etc/network/interfaces.d, on a continued line, which
# the recipe refuses to check
on static 'mkdir /etc/network/static.d && sed -n "/eth0/,\$p" /etc/network/interfaces >/etc/network/static.d/eth0
  printf "auto lo\niface lo inet loopback\n\nsource-directory \\\\\n  static.d\n" >/etc/network/interfaces'
check 'refuses to switch with eth0 in a sourced file' refused static '/etc/network/interfaces sources other files (source-directory static.d)'
# same again, with eth0 in /etc/network/interfaces.d as Debian's installer would source it
on static 'mv /etc/network/static.d/eth0 /etc/network/interfaces.d/eth0
  printf "source /etc/network/interfaces.d/*\n\nauto lo\niface lo inet loopback\n" >/etc/network/interfaces'
check 'refuses to switch with eth0 in /etc/network/interfaces.d' refused static '/etc/network/interfaces.d has files (eth0)'
check 'ifupdown still configures eth0 (10.98.0.20/24)' same_address static 4 10.98.0.20/24
check '/etc/network/interfaces is still there' on static '[ -e /etc/network/interfaces ] && [ ! -e /etc/network/interfaces.save ]'
check 'systemd-networkd is not running' on static '! systemctl is-active --quiet systemd-networkd'

## IPv6 disabled: still no public IPv6 with systemd-networkd, despite the IPv6 router

if $ipv6; then
  say "▶ IPv6 disabled with node['sanity']['ipv6'] = false"
  interfaces noipv6 allow-hotplug -
  echo '{"sanity": {"ipv6": false}}' >"$work/noipv6.json"
  boot noipv6 dhcpcd br0 02:00:00:00:00:20
  wait_for 30 has_address noipv6 4 || { echo "ifupdown didn't configure IPv4" >&2; exit 1; }
  state noipv6 >"$work/state-before-noipv6.log"
  check 'converges' converge noipv6 'recipe[sanity::ipv6],recipe[sanity::network]'
  check 'systemd-networkd configured eth0' wait_for 30 on noipv6 'networkctl list --no-legend eth0 | grep -q " configured"'
  settle
  check 'no public IPv6 address or route (link-local is fine)' no_public_ipv6 noipv6
  check 'converges again without changes' reconverged noipv6 'recipe[sanity::ipv6],recipe[sanity::network]'

  say "▶ IPv6 disabled with node['sanity']['ipv6'] = false, after a reboot"
  boot noipv6 dhcpcd br0 02:00:00:00:00:20
  check 'systemd-networkd configured eth0' wait_for 30 on noipv6 'networkctl list --no-legend eth0 | grep -q " configured"'
  settle
  check 'no public IPv6 address or route (link-local is fine)' no_public_ipv6 noipv6
  check 'converges without changes, sanity::ipv6 and systemd-networkd agree' \
    reconverged noipv6 'recipe[sanity::ipv6],recipe[sanity::network]'
fi

say ''
if [ $failures -gt 0 ]; then
  say "✘ $failures check(s) failed"
  exit 1
fi
say '✔ All checks passed'
