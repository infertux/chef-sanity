# Auto reboot weekly

cron 'auto_reboot' do
  action node['sanity']['auto_reboot']['action']
  hour 12
  minute 30
  weekday node['sanity'].dig('auto_reboot', 'weekday', node['ipaddress'])
  # TODO: replace with databag?
  user 'root'
  command '/sbin/reboot'
  only_if { node['sanity'].dig('auto_reboot', 'weekday', node['ipaddress']) }
end
