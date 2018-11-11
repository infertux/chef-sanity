Chef::Resource::CronD.send(:include, Sanity::Helpers) # to get `drand`

cron_d 'auto_reboot' do # ~FC009
  action node['sanity']['auto_reboot'] ? :create : :delete
  hour drand 24
  minute drand 60
  day node['sanity']['auto_reboot'] == 'monthly' ? (drand 28) + 1 : '*'
  weekday node['sanity']['auto_reboot'] == 'weekly' ? (drand 7) + 1 : '*'
  user 'root'
  # XXX: don't reboot if booted up for less than 24 hours
  command '/usr/bin/uptime | grep -v day || /sbin/reboot'
end
