default['sanity']['ipv6'] = true # set to false to disable IPv6
default['sanity']['root_email'] = ''

default['sanity']['ssh']['authorized_keys'] = nil # don't touch keys if nil/empty

default['sanity']['iptables']['ssh_authorized_ips_v4'] = nil # nil means to ANY source IP
default['sanity']['iptables']['ssh_authorized_ips_v6'] = nil # nil means to NO IPs, i.e. DROP

# To add extra repositories such as backports or testing:
default['sanity']['repositories']['testing'] = false
default['sanity']['repositories']['backports'] = \
  platform?('debian') && node['platform_version'].to_i == 10

default['sanity']['auto_reboot'] = 'monthly' # set to false to disable

default['sanity']['monit'] = {
  'duration' => '5 cycles',
  'cpu' => '75%',
  'loadavg' => node['cpu']['total'] || '1.0',
  'memory' => '75%',
  'swap' => '5%',
  'uptime' => '32 days',
  'filesystem' => { 'root' => '75%' },
}
