default['sanity']['ipv6'] = true # set to false to disable IPv6

default['sanity']['ssh']['authorized_keys'] = []

default['sanity']['iptables']['ssh_authorized_ips_v4'] = %w(0.0.0.0/0) # default to any source IP
default['sanity']['iptables']['ssh_authorized_ips_v6'] = %w() # default to no IPs, i.e. DROP

default['sanity']['aliases']['root'] = ''

# To add extra repositories such as backports or testing:
default['sanity']['apt_sources']['backports'] = false
default['sanity']['apt_sources']['testing'] = false

default['sanity']['auto_reboot']['action'] = 'create' # or 'delete'
# default['sanity']['auto_reboot']['weekday']['1.2.3.4'] = 1

default['sanity']['mta'] = 'postfix' # or 'msmtp'

default['sanity']['monit'] = {
  'duration' => '5 cycles',
  'cpu' => '75%',
  'loadavg' => node['cpu']['total'] || '1.0',
  'memory' => '75%',
  'swap' => '5%',
  'uptime' => '30 days',
  'filesystem' => { 'root' => '75%' },
}
