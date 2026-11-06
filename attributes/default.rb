# NOTE: Attributes are sorted alphabetically

default['sanity']['automatic_reboot'] = 'monthly' # set to false to disable

ipaddress = IPAddr.new(node['ipaddress'])
default['sanity']['ipv4_reachable'] = !ipaddress.private? && !ipaddress.link_local? && !ipaddress.loopback? # override to false if you don't have a reachable public IPv4
Chef::Log.info "Primary IPv4 address #{ipaddress} auto-detected as #{'NOT ' unless node['sanity']['ipv4_reachable']}reachable"

default['sanity']['ipv6'] = true # set to false to disable IPv6 (also makes SSH and Postfix use IPv4 only)

default['sanity']['email2telegram'] = {} # set token and chat_id to forward outgoing emails to Telegram

default['sanity']['firewall']['ssh_authorized_ips_v4'] = nil # nil means to ANY source IP
default['sanity']['firewall']['ssh_authorized_ips_v6'] = nil # nil means to NO IPs, i.e. DROP

default['sanity']['network']['interfaces']['manage'] = true

default['sanity']['monit'] = {
  'duration' => '5 cycles',
  'cpu' => '75%',
  'loadavg' => node['cpu']['total'] || '1.0',
  'memory' => '75%',
  'swap' => '5%',
  'uptime' => '32 days',
  'filesystem' => { '/' => '75%' },
  'start_delay' => 60 * 5, # in seconds
}

default['sanity']['ntp'] = 'systemd-timesyncd' # set to 'ntp' to use the ntp package instead of systemd

# Install useful packages
default['sanity']['packages']['install'] =
  %w(
    apt-forktracer
    btop
    cron
    curl
    rsync
    sudo
    systemd-coredump
    vim
  )

# Remove unwanted packages often installed by default
default['sanity']['packages']['purge'] = %w(bind9)

default['sanity']['packages']['fail_on_leftover_configuration_files'] = false

default['sanity']['postfix']['inet_protocols'] = nil # nil means 'all', or 'ipv4' if IPv6 is disabled; set to 'ipv4' to keep IPv6 but not for Postfix
default['sanity']['postfix']['relay'] = {} # set host (e.g. '[smtp.example.net]:587') to send all emails through that relay from root_email, plus username and password if it requires authentication

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

default['sanity']['sysstat']['enable'] = true # set to false to stop recording system activity and purge sysstat, which deletes the recorded history in /var/log/sysstat
default['sanity']['sysstat']['interval'] = 1 # in minutes, how often to record system activity: must divide 60 (1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30 or 60)
