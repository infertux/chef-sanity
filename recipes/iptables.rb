node.default['iptables-ng']['auto_prune_attribute_rules'] = true
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

iptables_ng_rule '10-icmpv4' do
  ip_version 4
  rule [
    '-p icmp --icmp-type echo-request -j ACCEPT' # ping
  ]
end

iptables_ng_rule '10-dhcpv4' do
  ip_version 4
  rule [
    '-p udp --sport 67 --dport 68 -d 255.255.255.255 -j ACCEPT', # allow DHCPOFFER message
    '-p udp --sport 68 --dport 67 -s 0.0.0.0 -d 255.255.255.255 -j DROP', # ignore DHCPREQUEST message
  ]
end

iptables_ng_rule '10-icmpv6' do
  ip_version 6
  rule [
    '-p icmpv6 --icmpv6-type echo-request -j ACCEPT', # ping type 128
    '-p icmpv6 --icmpv6-type router-advertisement -j ACCEPT', # https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol type 134
    '-p icmpv6 --icmpv6-type neighbour-solicitation -j ACCEPT', # https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol type 135
    '-p icmpv6 --icmpv6-type neighbour-advertisement -j ACCEPT', # https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol type 136
  ]
end

# FIXME:
raise "ssh_authorized_ips (#{node['sanity']['iptables']['ssh_authorized_ips'].inspect}) no longer exist" if node['sanity']['iptables']['ssh_authorized_ips']

iptables_ng_rule '20-ssh' do
  ip_version 4
  rule node['sanity']['iptables']['ssh_authorized_ips_v4'].map { |ip| "-p tcp -m conntrack --ctstate NEW --dport 22 -s #{ip} -j ACCEPT" }
  not_if { node['sanity']['iptables']['ssh_authorized_ips_v4'].empty? }
end

iptables_ng_rule '20-ssh' do
  action :delete
  ip_version 4
  only_if { node['sanity']['iptables']['ssh_authorized_ips_v4'].empty? }
end

iptables_ng_rule '20-ssh' do
  ip_version 6
  rule node['sanity']['iptables']['ssh_authorized_ips_v6'].map { |ip| "-p tcp -m conntrack --ctstate NEW --dport 22 -s #{ip} -j ACCEPT" }
  not_if { node['sanity']['iptables']['ssh_authorized_ips_v6'].empty? }
end

iptables_ng_rule '20-ssh' do
  action :delete
  ip_version 6
  only_if { node['sanity']['iptables']['ssh_authorized_ips_v6'].empty? }
end

iptables_ng_rule '30-mass-scan' do
  ip_version 4
  rule [
    '-s 23.92.36.2 -j DROP', # US
    '-s 23.96.189.32 -j DROP', # US / Microsoft
    '-s 52.176.108.199 -j DROP', # US / Microsoft
    '-s 52.187.124.3 -j DROP', # US / Microsoft
    '-s 52.228.28.160 -j DROP', # US / Microsoft
    '-s 52.228.29.179 -j DROP', # US / Microsoft
    '-s 52.228.30.50 -j DROP', # US / Microsoft
    '-s 52.228.71.224 -j DROP', # US / Microsoft
    '-s 77.72.82.135 -j DROP', # UK
    '-s 77.72.82.175 -j DROP', # UK
    '-s 77.72.82.96 -j DROP', # UK
    '-s 129.13.252.47 -j DROP', # DE
    '-s 136.243.139.96 -j DROP', # DE / Hetzner
    '-s 159.65.205.242 -j DROP', # US / DigitalOcean
    '-s 178.159.37.99 -j DROP', # UA
    '-s 218.12.231.80 -j DROP', # CN
  ]
end

iptables_ng_rule '30-common-ports' do
  rule [
    '-p tcp --dport 21 -j DROP',
    '-p tcp --dport 22 -j DROP',
    '-p tcp --dport 23 -j DROP',
    '-p tcp --dport 25 -j DROP',
    '-p tcp --dport 53 -j DROP',
    '-p tcp --dport 445 -j DROP',
    '-p tcp --dport 1433 -j DROP',
    '-p tcp --dport 5060:5061 -j DROP', # SIP

    '-p udp --sport 138 --dport 138 -j DROP', # NetBIOS
    '-p udp --dport 5060 -j DROP', # SIP
  ]
end

iptables_ng_rule '90-log' do
  chain 'INPUT'
  rule '-j LOG --log-level notice --log-prefix "iptables:filter:INPUT "'
end

iptables_ng_rule '90-log' do
  chain 'FORWARD'
  rule '-j LOG --log-prefix "iptables:filter:FORWARD "'
end
