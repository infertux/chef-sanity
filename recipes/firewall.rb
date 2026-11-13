# XXX: allow any IPv4 if nil
ssh_authorized_ips_v4 = node['sanity']['firewall']['ssh_authorized_ips_v4']
ssh_authorized_ips_v4 ||= %w(0.0.0.0/0)

# XXX: block all IPv6 if nil
ssh_authorized_ips_v6 = Array(node['sanity']['firewall']['ssh_authorized_ips_v6'])

package %w(iptables-persistent libiptc0) do
  action :purge
end

%w(iptables iptables.d).each do |dir|
  directory "/etc/#{dir}" do
    action :delete
    recursive true
  end
end

package 'nftables'

directory '/etc/nftables.d' do
  owner 'root'
  group 'root'
  mode '0500'
end

template '/etc/nftables.conf' do
  source 'firewall/nftables.conf.erb'
  owner 'root'
  group 'root'
  mode '0500'
  verify 'nft --check -f %{path}' # a configuration nft can't load would also leave no firewall at the next boot
  notifies :reload, 'service[nftables]', :immediately
  variables(
    ssh_authorized_ips_v4: ssh_authorized_ips_v4,
    ssh_authorized_ips_v6: ssh_authorized_ips_v6,
  )
end

# Reload rather than restart to apply changes: reloading applies /etc/nftables.conf in a single transaction, which
# keeps the current rules if it fails, while restarting flushes them first and would leave no firewall at all.
# A reload does nothing when the service isn't active, so it's started here, after the configuration is written:
# starting it before would load the previous one, which can't be repaired if nft rejects it.
service 'nftables' do
  supports reload: true
  action %i(enable start)
end

# Rebuild custom.nft at the end of every run, from the sanity_nft rules declared by then: this also empties it when the
# last one is removed.
sanity_firewall 'default' do
  delayed_action :rebuild
end
