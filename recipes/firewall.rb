# XXX: allow any IPv4 if nil
ssh_authorized_ips_v4 = node['sanity']['firewall']['ssh_authorized_ips_v4']
ssh_authorized_ips_v4 ||= %w(0.0.0.0/0)

# XXX: block all IPv6 if nil
ssh_authorized_ips_v6 = Array(node['sanity']['firewall']['ssh_authorized_ips_v6'])

case node['sanity']['firewall']['type']
when 'nftables'
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

  service 'nftables' do
    action %i(enable)
  end

  execute 'nft-check' do
    action :nothing
    command 'nft --check -f /etc/nftables.conf'
    notifies :restart, 'service[nftables]', :immediately
  end

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
    notifies :run, 'execute[nft-check]'
    variables(
      ssh_authorized_ips_v4: ssh_authorized_ips_v4,
      ssh_authorized_ips_v6: ssh_authorized_ips_v6,
    )
  end

  sanity_firewall # initialize the default ruleset

else
  raise NotImplementedError, "Unknown firewall #{node['sanity']['firewall']['type'].inspect}"
end
