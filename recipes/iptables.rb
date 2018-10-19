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
    '-p udp --sport 67 --dport 68 -d 255.255.255.255 -j ACCEPT', # allow DHCPOFFER message
    '-p udp --sport 68 --dport 67 -s 0.0.0.0 -d 255.255.255.255 -j DROP', # ignore DHCPREQUEST message
  ]
end

# XXX: See http://shouldiblockicmp.com/
# `ip6tables -p icmpv6 -h` outputs all ICMPv6 types
iptables_ng_rule '10-icmpv6' do
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
    '-s 37.201.210.183 -j DROP', # DE
    '-s 39.105.27.78 -j DROP', # CN / HTTP script kiddie
    '-s 47.75.150.232 -j DROP', # CN / HTTP script kiddie
    '-s 47.91.158.122 -j DROP', # CN / HTTP script kiddie
    '-s 52.176.108.199 -j DROP', # US / Microsoft
    '-s 52.187.124.3 -j DROP', # US / Microsoft
    '-s 52.228.28.160 -j DROP', # US / Microsoft
    '-s 52.228.29.179 -j DROP', # US / Microsoft
    '-s 52.228.30.50 -j DROP', # US / Microsoft
    '-s 52.228.71.224 -j DROP', # US / Microsoft
    '-s 77.72.82.135 -j DROP', # UK
    '-s 77.72.82.175 -j DROP', # UK
    '-s 77.72.82.96 -j DROP', # UK
    '-s 89.36.185.5 -j DROP', # IR / HTTP script kiddie
    '-s 95.90.249.36 -j DROP',
    '-s 104.200.67.226 -j DROP', # US / port scan
    '-s 106.12.26.234 -j DROP', # CN / HTTP script kiddie
    '-s 115.205.66.205 -j DROP', # CN / HTTP script kiddie
    '-s 120.79.18.73 -j DROP', # CN / HTTP script kiddie
    '-s 121.135.240.177 -j DROP', # KR / HTTP script kiddie
    '-s 123.207.158.82 -j DROP', # CN / HTTP script kiddie
    '-s 129.13.252.47 -j DROP', # DE
    '-s 136.243.139.96 -j DROP', # DE / Hetzner
    '-s 145.249.104.135 -j DROP', # NL / HTTP script kiddie
    '-s 159.65.205.242 -j DROP', # US / DigitalOcean
    '-s 176.9.137.25 -j DROP',
    '-s 178.159.37.99 -j DROP', # UA
    '-s 182.61.171.57 -j DROP', # CN / HTTP script kiddie
    '-s 195.56.150.75 -j DROP', # HU
    '-s 198.12.156.234 -j DROP', # US / GoDaddy.com
    '-s 201.24.225.137 -j DROP',
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
    '-p udp --dport 53 -j DROP',
    '-p udp --dport 500 -j DROP', # IKE
    '-p tcp --dport 1433 -j DROP',
    '-p tcp --dport 5060:5061 -j DROP', # SIP
    '-p udp --dport 5060 -j DROP', # SIP

    '-p tcp -m multiport --dports bootps,bootpc,netbios-ns,netbios-dgm,netbios-ssn,microsoft-ds -j DROP', # NetBIOS
    '-p udp -m multiport --dports bootps,bootpc,netbios-ns,netbios-dgm,netbios-ssn,microsoft-ds -j DROP', # NetBIOS
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
