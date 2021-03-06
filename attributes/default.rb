# NOTE: Attributes are sorted alphabetically

default['sanity']['automatic_reboot'] = 'monthly' # set to false to disable

default['sanity']['ipv6'] = true # set to false to disable IPv6

default['sanity']['firewall'] = \
  platform?('debian') && node['platform_version'].to_i == 10 ? 'nftables' : 'iptables'

default['sanity']['network']['interfaces']['manage'] = true

default['sanity']['network']['interfaces'] = {
  'lo' => <<~LO,
    # The loopback network interface
    auto lo
    iface lo inet loopback
  LO
  node['network']['default_interface'] => <<~DEFAULT,
    # The primary network interface
    allow-hotplug #{node['network']['default_interface']}
    iface #{node['network']['default_interface']} inet dhcp
  DEFAULT
}

default['sanity']['network']['interfaces'][node['network']['default_interface']] << <<~IPv6 if node['sanity']['ipv6']
  # This is an autoconfigured IPv6 interface
  iface #{node['network']['default_interface']} inet6 auto
IPv6

default['sanity']['iptables']['ssh_authorized_ips_v4'] = nil # nil means to ANY source IP
default['sanity']['iptables']['ssh_authorized_ips_v6'] = nil # nil means to NO IPs, i.e. DROP

default['sanity']['monit'] = {
  'duration' => '5 cycles',
  'cpu' => '75%',
  'loadavg' => node['cpu']['total'] || '1.0',
  'memory' => '75%',
  'swap' => '5%',
  'uptime' => '32 days',
  'filesystem' => { '/' => '75%' },
}

default['sanity']['ntp'] = 'systemd-timesyncd' # set to 'ntp' to use the ntp package instead of systemd

# XXX: Enable backports for Debian 10 to get Monit.
# All backports are deactivated by default (i.e. the packages are pinned to 100 by using ButAutomaticUpgrades: yes in the Release files.
default['sanity']['repositories']['backports'] = \
  platform?('debian') && node['platform_version'].to_i == 10
default['sanity']['repositories']['testing'] = false
default['sanity']['repositories']['protocol'] = 'https' # http|https

# Use Cloudflare & OpenDNS by default
default['sanity']['resolver']['dns'] = %w(1.1.1.1 208.67.222.222)
default['sanity']['resolver']['dns'] |= %w(2606:4700:4700::1111 2620:119:35::35) if node['sanity']['ipv6']

default['sanity']['root_email'] = '' # administrator's email

default['sanity']['ssh']['authorized_keys'] = nil # don't touch keys if nil/empty

default['sanity']['vrms']['whitelist'] = '@' # can be a regexp of whitelisted non-free packages
