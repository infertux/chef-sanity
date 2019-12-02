# NOTE: Attributes are sorted alphabetically

default['sanity']['automatic_reboot'] = 'monthly' # set to false to disable

default['sanity']['firewall'] = \
  platform?('debian') && node['platform_version'].to_i == 10 ? 'nftables' : 'iptables'

default['sanity']['iptables']['ssh_authorized_ips_v4'] = nil # nil means to ANY source IP
default['sanity']['iptables']['ssh_authorized_ips_v6'] = nil # nil means to NO IPs, i.e. DROP

default['sanity']['ipv6'] = true # set to false to disable IPv6

default['sanity']['monit'] = {
  'duration' => '5 cycles',
  'cpu' => '75%',
  'loadavg' => node['cpu']['total'] || '1.0',
  'memory' => '75%',
  'swap' => '5%',
  'uptime' => '32 days',
  'filesystem' => { 'root' => '75%' },
}

# XXX: Enable backports for Debian 10 to get Monit.
# All backports are deactivated by default (i.e. the packages are pinned to 100 by using ButAutomaticUpgrades: yes in the Release files.
default['sanity']['repositories']['backports'] = \
  platform?('debian') && node['platform_version'].to_i == 10
default['sanity']['repositories']['testing'] = false

default['sanity']['root_email'] = '' # administrator's email

default['sanity']['ssh']['authorized_keys'] = nil # don't touch keys if nil/empty
