return unless node['sanity']['network']['interfaces']['manage']

interface = node['network']['default_interface']
raise "Unexpected default interface: #{interface}" unless interface.start_with?('e')

# systemd-networkd only gets DHCP and IPv6 autoconfiguration (see 20-wired.network below): refuse to replace any other
# configuration, e.g. a static address would be lost, or silently replaced by another one if a DHCP server answers
if ::File.exist?('/etc/network/interfaces')
  config = ::File.read('/etc/network/interfaces').gsub("\\\n", '') # a line ending with a backslash goes on with the next one
  problems = []

  methods = config.scan(/^\s*iface\s+\S+\s+(\S+)\s+(\S+)/).map { |family, method| "#{family} #{method}" }.uniq
  methods -= ['inet loopback', 'inet6 loopback', 'inet dhcp', 'inet6 auto']
  problems << "/etc/network/interfaces uses #{methods.join(', ')}" unless methods.empty?

  # Sourced files can't be checked reliably, ifupdown expands their paths like a shell (see interfaces(5)): only accept
  # the source directive written by Debian's installer, for /etc/network/interfaces.d, which must be empty
  sources = config.scan(/^\s*source(?:-directory)?\s.*$/).map { |line| line.split.join(' ') }
  sources -= ['source /etc/network/interfaces.d/*', 'source-directory /etc/network/interfaces.d']
  problems << "/etc/network/interfaces sources other files (#{sources.join(', ')})" unless sources.empty?
  custom = ::Dir.exist?('/etc/network/interfaces.d') ? ::Dir.children('/etc/network/interfaces.d').sort : []
  problems << "/etc/network/interfaces.d has files (#{custom.join(', ')})" unless custom.empty?

  raise "Refusing to switch to systemd-networkd, which only gets DHCP and IPv6 autoconfiguration: #{problems.join('; ')} (convert the configuration manually or set node['sanity']['network']['interfaces']['manage'] to false)" unless problems.empty?
end

directory '/etc/network/interfaces.d' do
  action :delete # empty, see above
end

systemd_unit 'systemd-networkd.service' do
  action %i(enable)
end

# Without IPv6, systemd-networkd must neither get public addresses and routes from router advertisements, nor enable
# IPv6 on the interfaces again for link-local addresses, which sanity::ipv6 would disable again on the next Chef run
ipv6 = node['sanity']['ipv6'] ? 'IPv6AcceptRA=true' : "IPv6AcceptRA=false\nLinkLocalAddressing=no"

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
    #{ipv6}

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
