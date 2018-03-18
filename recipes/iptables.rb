node.default['iptables-ng']['auto_prune_attribute_rules'] = true
node.default['iptables-ng']['rules']['filter']['INPUT']['default'] = 'DROP [0:0]'
node.default['iptables-ng']['rules']['filter']['FORWARD']['default'] = 'DROP [0:0]'
node.default['iptables-ng']['rules']['filter']['OUTPUT']['default'] = 'ACCEPT [0:0]'

include_recipe 'iptables-ng::default'

iptables_ng_rule '10-lo' do
  rule '-i lo -j ACCEPT'
end

iptables_ng_rule '10-established' do
  rule '-m state --state ESTABLISHED,RELATED -j ACCEPT'
end

iptables_ng_rule '10-ping' do
  ip_version 4
  rule '-p icmp --icmp-type 8 -j ACCEPT'
end

iptables_ng_rule '20-ssh' do
  ip_version 4
  rule node['sanity']['iptables']['ssh_authorized_ips'].map { |ip| "-p tcp -m state --state NEW --dport 22 -s #{ip} -j ACCEPT" }
end

iptables_ng_rule '30-mass-scan' do
  ip_version 4
  rule [
    '-s 23.96.189.32 -j DROP', # mass scan from US / Microsoft
    '-s 52.176.108.199 -j DROP', # mass scan from US / Microsoft
    '-s 52.187.124.3 -j DROP', # mass scan from US / Microsoft
    '-s 52.228.28.160 -j DROP', # mass scan from US / Microsoft
    '-s 52.228.29.179 -j DROP', # mass scan from US / Microsoft
    '-s 52.228.30.50 -j DROP', # mass scan from US / Microsoft
    '-s 52.228.71.224 -j DROP', # mass scan from US / Microsoft
    '-s 77.72.82.135 -j DROP', # mass scan from UK
    '-s 77.72.82.175 -j DROP', # mass scan from UK
    '-s 77.72.82.96 -j DROP', # mass scan from UK
    '-s 178.159.37.99 -j DROP', # mass scan from UA
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

service 'rsyslog' do
  action :nothing
end

file '/etc/rsyslog.d/30-iptables.conf' do
  content <<-CONF.gsub(/^\s+/, '')
    :msg,contains,"iptables:" /var/log/iptables.log
    & stop
  CONF
  notifies :restart, 'service[rsyslog]', :immediately
end
