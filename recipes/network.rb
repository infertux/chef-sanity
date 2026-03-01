return unless node['sanity']['network']['interfaces']['manage']

raise "Unexpected default interface: #{node['network']['default_interface']}" unless node['network']['default_interface'].start_with?('e')

directory '/etc/network/interfaces.d' do
  action :delete # XXX: will fail on purpose if any custom files are present
end

reboot 'soon' do
  only_if { ::File.exist? '/etc/network/interfaces' }
  action :request_reboot
  reason 'Reboot required to apply new settings. Will reboot in 5 minutes.'
  delay_mins 5
end

execute 'back up old interfaces file' do
  only_if { ::File.exist? '/etc/network/interfaces' }
  command 'mv /etc/network/interfaces /etc/network/interfaces.save'
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

systemd_unit 'systemd-networkd.service' do
  action %i(start)
end
