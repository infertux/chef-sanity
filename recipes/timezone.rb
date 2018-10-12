# Set TZ to UTC

case node['platform_family']
when 'debian', 'rhel'
  execute 'set-timezone UTC' do
    command 'timedatectl set-timezone UTC'
    not_if "timedatectl status | grep 'Time zone: UTC'"
  end

  execute 'set-ntp true' do
    command 'timedatectl set-ntp true'
    not_if "timedatectl status | grep -E '(Network time on|systemd-timesyncd\.service active): yes'"
  end

else
  raise NotImplementedError, "Don't know how to handle timezone for platform #{node['platform_family']}"
end
