cron 'auto_reboot' do
  action :delete # FIXME: remove
end

cron_d 'auto_reboot' do
  action node['sanity']['auto_reboot'] ? :create : :delete
  hour node['hostname'].hash % 24
  minute node['hostname'].hash % 60
  day node['sanity']['auto_reboot'] == 'monthly' ? node['hostname'].hash % 28 + 1 : '*'
  weekday node['sanity']['auto_reboot'] == 'weekly' ? node['hostname'].hash % 7 + 1 : '*'
  user 'root'
  command '/sbin/reboot'
end
