# XXX: allow any IPv4 if nil
ssh_authorized_ips_v4 = node['sanity']['firewall']['ssh_authorized_ips_v4']
ssh_authorized_ips_v4 ||= %w(0.0.0.0/0)

# XXX: block all IPv6 if nil
ssh_authorized_ips_v6 = Array(node['sanity']['firewall']['ssh_authorized_ips_v6'])

case node['sanity']['firewall']['type']
when 'nftables'
  package %w(iptables iptables-persistent libiptc0) do
    action :purge
  end

  # %w(iptables iptables.d).each do |dir|
  #   directory "/etc/#{dir}" do
  #     action :delete
  #     recursive true
  #   end
  # end

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
    mode '0550'
  end

  template '/etc/nftables.conf' do
    source 'firewall/nftables.conf.erb'
    owner 'root'
    group 'root'
    mode '0555'
    notifies :run, 'execute[nft-check]'
    variables(
      ssh_authorized_ips_v4: ssh_authorized_ips_v4,
      ssh_authorized_ips_v6: ssh_authorized_ips_v6,
    )
  end

when 'iptables'
  package 'nftables' do
    action :purge
  end

  package %w(iptables iptables-persistent)

  %w(iptables ip6tables).each do |program|
    # https://wiki.debian.org/iptables
    execute "update-alternatives to point to #{program}-legacy" do
      not_if "test $(readlink /etc/alternatives/#{program}) = /usr/sbin/#{program}-legacy"
      command "update-alternatives --set #{program} /usr/sbin/#{program}-legacy"
    end
  end

  node.default['iptables-ng']['auto_prune_attribute_rules'] = true
  node.default['iptables-ng']['enabled_ip_versions'] = [4] unless node['sanity']['ipv6']
  node.default['iptables-ng']['rules']['filter']['INPUT']['default'] = 'DROP [0:0]'
  node.default['iptables-ng']['rules']['filter']['FORWARD']['default'] = 'DROP [0:0]'
  node.default['iptables-ng']['rules']['filter']['OUTPUT']['default'] = 'ACCEPT [0:0]'

  include_recipe 'iptables-ng::default'

  iptables_ng_rule '10-lo' do
    rule '-i lo -j ACCEPT'
  end

  iptables_ng_rule '10-established' do
    rule '-m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT'
  end

  # XXX: See http://shouldiblockicmp.com/
  # `iptables -p icmp -h` outputs all ICMPv4 types
  iptables_ng_rule '10-icmpv4' do
    ip_version 4
    rule [
      '-p icmp --icmp-type echo-request -j ACCEPT', # ping / type 8
      '-p icmp --icmp-type fragmentation-needed -j ACCEPT', # MTU discovery / type 3
      '-p icmp --icmp-type time-exceeded -j DROP', # traceroute / type 11
    ]
  end

  iptables_ng_rule '10-dhcpv4' do
    ip_version 4
    rule [
      '-p udp --sport 67 --dport 68 -d 255.255.255.255 -j ACCEPT', # accept DHCPOFFER message
      '-p udp --sport 68 --dport 67 -s 0.0.0.0 -d 255.255.255.255 -j DROP', # ignore DHCPREQUEST message
    ]
  end

  # XXX: See http://shouldiblockicmp.com/
  # `ip6tables -p icmpv6 -h` outputs all ICMPv6 types
  iptables_ng_rule '10-icmpv6' do
    only_if { node['iptables-ng']['enabled_ip_versions'].include? 6 }
    ip_version 6
    rule [
      '-p icmpv6 --icmpv6-type echo-request -j ACCEPT', # ping / type 128
      '-p icmpv6 --icmpv6-type packet-too-big -j ACCEPT', # MTU discovery / type 2
      '-p icmpv6 --icmpv6-type time-exceeded -j DROP', # traceroute / type 3
      '-p icmpv6 --icmpv6-type router-advertisement -j ACCEPT', # https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol type 134
      '-p icmpv6 --icmpv6-type neighbour-solicitation -j ACCEPT', # https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol type 135
      '-p icmpv6 --icmpv6-type neighbour-advertisement -j ACCEPT', # https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol type 136
    ]
  end

  iptables_ng_rule '10-dhcpv6' do
    only_if { node['iptables-ng']['enabled_ip_versions'].include? 6 }
    ip_version 6
    rule [
      '-p udp --sport 547 --dport 546 -j ACCEPT',
    ]
  end

  iptables_ng_rule '20-ssh' do
    not_if { ssh_authorized_ips_v4.empty? }
    ip_version 4
    rule(
      Array(node['ssh-hardening']['ssh']['ports'] || 22).map do |port|
        ssh_authorized_ips_v4.map do |ip|
          "-p tcp -m conntrack --ctstate NEW --dport #{port} -s #{ip} -j ACCEPT"
        end
      end.flatten,
    )
  end

  iptables_ng_rule '20-ssh' do
    only_if { ssh_authorized_ips_v4.empty? }
    action :delete
    ip_version 4
  end

  iptables_ng_rule '20-ssh' do
    only_if { node['iptables-ng']['enabled_ip_versions'].include?(6) && !ssh_authorized_ips_v6.empty? }
    ip_version 6
    rule(
      Array(node['ssh-hardening']['ssh']['ports'] || 22).map do |port|
        ssh_authorized_ips_v6.map do |ip|
          "-p tcp -m conntrack --ctstate NEW --dport #{port} -s #{ip} -j ACCEPT"
        end
      end.flatten,
    )
  end

  iptables_ng_rule '20-ssh' do
    only_if { ssh_authorized_ips_v6.empty? }
    action :delete
    ip_version 6
  end

  iptables_ng_rule '30-common-ports' do
    rule [
      '-p tcp --dport 21 -j DROP',
      '-p tcp --dport 22 -j DROP',
      '-p tcp --dport 23 -j DROP',
      '-p tcp --dport 25 -j DROP',
      '-p tcp --dport 53 -j DROP',
      '-p udp --dport 53 -j DROP',
      '-p udp --dport 500 -j DROP', # IKE
      '-p tcp --dport 1433 -j DROP',
      '-p udp --dport 1900 -j DROP', # SSDP/UPnP
      '-p tcp --dport 5060:5061 -j DROP', # SIP
      '-p udp --dport 5060 -j DROP', # SIP

      '-p tcp -m multiport --dports 67,68,137,138,139,445 -j DROP', # NetBIOS
      '-p udp -m multiport --dports 67,68,137,138,139,445 -j DROP', # NetBIOS
    ]
  end

  iptables_ng_rule '80-spam' do
    rule '-p udp -j DROP' # UDP spam
  end

  iptables_ng_rule '80-high-ttl' do
    ip_version 4
    rule '-m ttl --ttl-gt 64 -j DROP' # abnormally high TTL
  end

  # see `dmesg --help | grep notice` for more information about log level
  # we limit logging to 1/second so attackers can't fill up the disk too quickly
  iptables_ng_rule '90-log' do
    rule '-m limit --limit 1/second --limit-burst 5 -j LOG --log-level notice --log-prefix "iptables:filter:INPUT "'
  end

  iptables_ng_rule '90-log' do
    chain 'FORWARD'
    rule '-m limit --limit 1/second --limit-burst 5 -j LOG --log-level notice --log-prefix "iptables:filter:FORWARD "'
  end
else
  raise NotImplementedError, "Unknown firewall #{node['sanity']['firewall']['type'].inspect}"
end
