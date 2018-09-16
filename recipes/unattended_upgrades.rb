# FIXME:
package 'cron-apt' do
  action :purge
end

%w(/var/lib/cron-apt /etc/cron-apt).each do |dir|
  directory dir do
    action :delete
    recursive true
  end
end

%w(/etc/cron.d/cron-apt /etc/apt/apt.conf.d/local).each do |dir|
  file dir do
    action :delete
  end
end

file '/etc/apt/apt.conf.d/02periodic' do
  action :delete
end
# /FIXME:

node.default['apt']['unattended_upgrades']['enable'] = true
node.default['apt']['unattended_upgrades']['allowed_origins'] = [] # allow all origins
node.default['apt']['unattended_upgrades']['origins_patterns'] = ['origin=*']
node.default['apt']['unattended_upgrades']['auto_fix_interrupted_dpkg'] = true
node.default['apt']['unattended_upgrades']['mail'] ||= node['sanity']['aliases']['root']
node.default['apt']['unattended_upgrades']['mail_only_on_error'] = false
node.default['apt']['unattended_upgrades']['remove_unused_dependencies'] = true
node.default['apt']['unattended_upgrades']['automatic_reboot'] = true

include_recipe 'apt::unattended-upgrades'
