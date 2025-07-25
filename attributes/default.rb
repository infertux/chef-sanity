# NOTE: Attributes are sorted alphabetically

default['sanity']['automatic_reboot'] = 'monthly' # set to false to disable

ipaddress = IPAddr.new(node['ipaddress'])
default['sanity']['ipv4_reachable'] = !ipaddress.private? && !ipaddress.link_local? # override to false if you don't have a reachable public IPv4
Chef::Log.info "Primary IPv4 address #{ipaddress} auto-detected as #{'NOT ' unless node['sanity']['ipv4_reachable']}reachable"

default['sanity']['ipv6'] = true # set to false to disable IPv6

default['sanity']['email2telegram'] = {} # set token and chat_id to forward outgoing emails to Telegram

default['sanity']['firewall']['type'] = 'nftables'
default['sanity']['firewall']['ssh_authorized_ips_v4'] = nil # nil means to ANY source IP
default['sanity']['firewall']['ssh_authorized_ips_v6'] = nil # nil means to NO IPs, i.e. DROP

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

default['sanity']['network']['interfaces'][node['network']['default_interface']] << <<~IPV6 if node['sanity']['ipv6']
  # This is an autoconfigured IPv6 interface
  iface #{node['network']['default_interface']} inet6 auto
IPV6

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

# Install useful packages
default['sanity']['packages']['install'] = \
  %w(
    apt-forktracer
    cron
    curl
    htop
    rsync
    sudo
    systemd-coredump
    vim
  )

# Remove unwanted packages often installed by default
default['sanity']['packages']['purge'] =
  value_for_platform_family(
    %w(debian) => %w(bind9 sysstat),
  )

default['sanity']['packages']['fail_on_leftover_configuration_files'] = false

default['sanity']['smartmontools']['enable'] = true # set to false for machines without HDD/SSD storage

# All backports are deactivated by default (i.e. the packages are pinned to 100 by using ButAutomaticUpgrades: yes in the Release files.
default['sanity']['repositories']['backports'] = false
default['sanity']['repositories']['testing'] = false
default['sanity']['repositories']['protocol'] = 'https' # http|https

# Use Cloudflare & OpenDNS by default
default['sanity']['resolver']['dns'] = %w(1.1.1.1 208.67.222.222)
default['sanity']['resolver']['dns'].unshift(*%w(2606:4700:4700::1111 2620:119:35::35)) if node['sanity']['ipv6']
default['sanity']['resolver']['dnssec'] = true

default['sanity']['root_email'] = '' # administrator's email

default['sanity']['ssh']['authorized_keys'] = nil # don't touch keys if nil/empty

default['sanity']['swap']['swappiness'] = 10
default['sanity']['swap']['swapfile']['path'] = '/swapfile'
default['sanity']['swap']['swapfile']['size'] = 0 # in GiB, set to 0 to disable
