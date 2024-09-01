if platform_family?('debian')
  package 'apt-transport-https'

  apt_update
end

include_recipe 'sanity::swap'
include_recipe 'sanity::ipv6'
include_recipe 'sanity::network'
include_recipe 'sanity::ntp'
include_recipe 'sanity::timezone'
include_recipe 'sanity::resolver'
include_recipe 'sanity::repositories'
include_recipe 'sanity::packages'
include_recipe 'sanity::ssh'
include_recipe 'sanity::firewall'
include_recipe 'sanity::postfix'
include_recipe 'sanity::email2telegram'
include_recipe 'sanity::unattended_upgrades'
include_recipe 'sanity::automatic_reboot'
include_recipe 'sanity::monit'
include_recipe 'sanity::smartmontools'
include_recipe 'sanity::vrms'
include_recipe 'sanity::os_hardening' # XXX: it should be last, as per https://github.com/dev-sec/chef-os-hardening#usage
