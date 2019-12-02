case node['platform_family']
when 'debian'
  node.default['apt']['unattended_upgrades']['enable'] = true
  node.default['apt']['unattended_upgrades']['allowed_origins'] = [] # allow all origins
  node.default['apt']['unattended_upgrades']['origins_patterns'] = ['origin=*']
  node.default['apt']['unattended_upgrades']['auto_fix_interrupted_dpkg'] = true
  node.default['apt']['unattended_upgrades']['mail'] ||= node['sanity']['root_email']
  node.default['apt']['unattended_upgrades']['sender'] ||= node['sanity']['root_email']
  node.default['apt']['unattended_upgrades']['remove_unused_dependencies'] = true
  node.default['apt']['unattended_upgrades']['automatic_reboot'] = node['sanity']['automatic_reboot']

  include_recipe 'apt::unattended-upgrades'
else
  Chef::Log.warn "No unattended-upgrades on platform #{node['platform']}"
end
