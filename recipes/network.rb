return unless node['sanity']['network']['interfaces']['manage']

interface = node['network']['default_interface']
raise "Unexpected default interface: #{interface}" unless interface.start_with?('e')

directory '/etc/network/interfaces.d' do
  action :delete # XXX: will fail on purpose if any custom files are present
end

systemd_unit 'systemd-networkd.service' do
  action %i(enable)
end

file '/etc/systemd/network/20-wired.network' do
  owner 'root'
  group 'root'
  mode '0444'
  notifies :try_restart, 'systemd_unit[systemd-networkd.service]'
  content <<~CONF
    [Match]
    Name=e*
    Type=ether

    [Network]
    DHCP=ipv4
    IPv6AcceptRA=true

    [DHCPv4]
    UseDNS=false

    [DHCPv6]
    UseDNS=false

    [IPv6AcceptRA]
    UseDNS=false
  CONF
end

# Hand the interfaces over from ifupdown to systemd-networkd without rebooting: stopping ifupdown's units
# runs ifdown, which stops its DHCP client that would otherwise keep running alongside systemd-networkd's.
# ifdown needs /etc/network/interfaces, so it is only moved away afterwards (the file is left behind
# when ifupdown is purged, hence the check).
# It runs as a transient unit so that it completes even if the Chef run gets killed midway, e.g. with
# the SSH session it runs from.
execute 'switch from ifupdown to systemd-networkd' do
  only_if { ::File.exist? '/etc/network/interfaces' }
  command ['systemd-run', '--wait', '--collect', '--unit=sanity-network-switch', '/bin/sh', '-ec', <<~SH]
    if [ -x /usr/sbin/ifdown ]; then systemctl stop networking.service 'ifup@*.service'; fi
    mv /etc/network/interfaces /etc/network/interfaces.save
    systemctl restart systemd-networkd.service
  SH
  notifies :run, 'execute[wait for the network to come back online]', :immediately
end

execute 'wait for the network to come back online' do
  action :nothing
  command "/usr/lib/systemd/systemd-networkd-wait-online --interface=#{interface} --ipv4 --timeout=60"
  not_if { ENV.key?('TEST_KITCHEN') } # XXX: Docker configures the containers' interfaces, systemd-networkd never brings them online
end

systemd_unit 'systemd-networkd.service' do
  action %i(start)
end
