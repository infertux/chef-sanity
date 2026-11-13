# Set up NTP client

ntp = node['sanity']['ntp']
raise ArgumentError, "node['sanity']['ntp'] must be 'systemd-timesyncd' or 'ntp', got #{ntp.inspect}" unless %w(systemd-timesyncd ntp).include?(ntp)

# Debian's NTP daemon is ntpsec since Debian 12, which made ntp a transitional package for it
package %w(ntp ntpsec) do
  action :purge
  not_if { ntp == 'ntp' }
end

package 'ntpsec' do
  only_if { ntp == 'ntp' }
end

package 'systemd-timesyncd' do
  only_if { ntp == 'systemd-timesyncd' }
end

execute 'set-ntp true' do
  command 'timedatectl set-ntp true'
  only_if { ntp == 'systemd-timesyncd' }
  not_if "timedatectl show 2>&1 | grep -qE '^NTP=yes$'"
end
