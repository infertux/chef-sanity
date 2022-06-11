Chef::Resource::CronD.include Sanity::Helpers # to get `drand`

cron_d 'automatic_reboot' do
  action node['sanity']['automatic_reboot'] ? :create : :delete
  hour drand 24
  minute drand 60
  day node['sanity']['automatic_reboot'] == 'monthly' ? (drand 28) + 1 : '*'
  weekday node['sanity']['automatic_reboot'] == 'weekly' ? (drand 7) + 1 : '*'
  user 'root'
  # XXX: don't reboot if booted up for less than 24 hours
  command '/usr/bin/uptime | grep -vq day || /bin/systemctl reboot'
end
