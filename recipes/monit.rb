node.default['monit']['config']['mail_servers'] = [{ hostname: 'localhost', port: 25 }]
node.default['monit']['config']['start_delay'] = 60 * 5

unless node['sanity']['root_email'].empty?
  node.default['monit']['config']['alert'] = [{
    name: node['sanity']['root_email'],
    but_not_on: ['instance'],
  }]
end

include_recipe 'monit-ng::default'

cmd = Mixlib::ShellOut.new('df -x devtmpfs -x tmpfs -x overlay --output=target')
cmd.run_command
cmd.error! # raise an exception if it didn't exit with 0
filesystems = cmd.stdout.lines.map(&:strip).drop(1)

check_filesystems = filesystems.map do |filesystem|
  name = filesystem[1..-1] # cannot start with a slash
  name = 'root' if name.empty?
  space_usage = node['sanity']['monit']['filesystem'][filesystem]
  space_usage ||= node['sanity']['monit']['filesystem']['/']

  "check filesystem #{name} with path #{filesystem}\nif space usage > #{space_usage} then alert"
end.join("\n")

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

    #{check_filesystems}
  MONIT
end
