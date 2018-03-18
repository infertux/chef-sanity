node.default['monit']['config']['start_delay'] = 60 * 5

unless node['sanity']['aliases']['root'].empty?
  node.default['monit']['config']['alert'] = [{
    name: node['sanity']['aliases']['root'],
    but_not_on: ['instance'],
  }]
end

include_recipe 'monit-ng::default'

file '/etc/monit/conf.d/system.conf' do
  owner 'root'
  group 'root'
  mode '0444'
  notifies :reload, 'service[monit]'
  content <<-MONIT.gsub(/^\s+/, '')
    check system $HOST
      if loadavg (5min) > 1.0 for 3 cycles then alert
      if memory usage > 50% for 3 cycles then alert
      if swap usage > 0% then alert
      if cpu usage > 50% for 3 cycles then alert
      if uptime > 30 days then alert

    check filesystem root with path /
      if space usage > 75% then alert
  MONIT
end
