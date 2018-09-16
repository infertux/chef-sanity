include_recipe 'sanity::timezone'
include_recipe 'sanity::resolver'
include_recipe 'sanity::openssh'
include_recipe 'sanity::ssh'
include_recipe 'sanity::iptables'
include_recipe 'sanity::mta'
include_recipe 'sanity::aliases'
include_recipe 'sanity::apt_sources'
include_recipe 'sanity::apt_clean'
include_recipe 'sanity::auto_reboot'
include_recipe 'sanity::tmux'
include_recipe 'sanity::htop'
include_recipe 'sanity::cronapt'
include_recipe 'sanity::monit'
include_recipe 'sanity::nginx'
include_recipe 'sanity::vim'
include_recipe 'sanity::apt_autoremove'
include_recipe 'sanity::vrms'

# include_recipe 'sanity::apt_update'
# include_recipe 'sanity::ipv6_disable'
# include_recipe 'sanity::fluentbit'
# include_recipe 'sanity::zeyple'
