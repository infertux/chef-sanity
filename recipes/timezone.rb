# Set TZ to UTC

case node['platform_family']
when 'debian'
  execute 'set-timezone UTC' do
    command 'timedatectl set-timezone UTC'
    not_if "timedatectl status | grep 'Time zone: UTC'"
  end

  execute 'set-ntp true' do
    command 'timedatectl set-ntp true'
    not_if "timedatectl status | grep 'Network time on: yes'"
  end

else
  raise "Don't know how to handle timezone for platform #{node['platform_family']}"
end
