# Set up NTP client

package 'ntp' do
  action :purge
  not_if { node['sanity']['ntp'] == 'ntp' }
end

package 'systemd-timesyncd' do
  only_if { node['sanity']['ntp'] == 'systemd-timesyncd' }
end

execute 'set-ntp true' do
  command 'timedatectl set-ntp true'
  only_if { node['sanity']['ntp'] == 'systemd-timesyncd' }
  not_if "timedatectl show 2>&1 | grep -qE '^NTP=yes$'"
end
