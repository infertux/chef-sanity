case node['sanity']['mta']
when 'postfix'
  node.default['postfix']['aliases']['root'] ||= node['sanity']['aliases']['root']
  node.default['postfix']['main']['inet_interfaces'] = 'all'
  include_recipe 'postfix::default'

when 'msmtp'
  include_recipe 'msmtp::default'

when false
  puts 'Warning: no MTA will be installed'

else
  raise "Invalid MTA: #{node['sanity']['mta'].inspect}"
end
