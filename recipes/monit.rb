codename = node['lsb']['codename'] || raise('no codename')

apt_repository "#{codename}-backports" do
  uri 'https://deb.debian.org/debian'
  distribution "#{codename}-backports"
  components %w(main)
  action :add
  only_if { node['platform'] == 'debian' && node['platform_version'].to_i == 10 }
end

node.default['monit']['config']['mail_servers'] = [ { hostname: 'localhost', port: 25 } ]
node.default['monit']['config']['start_delay'] = 60 * 5

unless node['sanity']['root_email'].empty?
  node.default['monit']['config']['alert'] = [{
    name: node['sanity']['root_email'],
    but_not_on: ['instance'],
  }]
end

include_recipe 'monit-ng::default'

file "#{node['monit']['conf_dir']}/system.conf" do
  owner 'root'
  group 'root'
  mode '0444'
  notifies :reload, 'service[monit]'
  content <<-MONIT.gsub(/^\s+/, '')
    check system $HOST
      if cpu usage > #{node['sanity']['monit']['cpu']} for #{node['sanity']['monit']['duration']} then alert
      if loadavg (5min) > #{node['sanity']['monit']['loadavg']} for #{node['sanity']['monit']['duration']} then alert
      if memory usage > #{node['sanity']['monit']['memory']} for #{node['sanity']['monit']['duration']} then alert
      if swap usage > #{node['sanity']['monit']['swap']} for #{node['sanity']['monit']['duration']} then alert
      if uptime > #{node['sanity']['monit']['uptime']} then alert

    check filesystem root with path /
      if space usage > #{node['sanity']['monit']['filesystem']['root']} then alert
  MONIT
end
