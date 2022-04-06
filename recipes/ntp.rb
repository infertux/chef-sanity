# Set up NTP client

case node['platform_family']
when 'debian', 'rhel'
  package 'ntp' do
    action :purge
    not_if { node['sanity']['ntp'] == 'ntp' }
  end

  execute 'set-ntp true' do
    command 'timedatectl set-ntp true'
    only_if { node['sanity']['ntp'] == 'systemd-timesyncd' }
    not_if "timedatectl show 2>&1 | grep -qE '^NTP=yes$'"
  end
else
  raise NotImplementedError, "Don't know how to handle NTP for platform #{node['platform_family']}"
end
