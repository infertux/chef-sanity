# Set TZ to UTC

case node['platform_family']
when 'debian'
  execute 'dpkg-reconfigure tzdata' do
    action :nothing
    command 'dpkg-reconfigure -f noninteractive tzdata'
  end

  file '/etc/timezone' do
    owner 'root'
    group 'root'
    mode  '0644'
    content 'Etc/UTC'
    notifies :run, 'execute[dpkg-reconfigure tzdata]', :immediately
  end

  link '/etc/localtime' do
    to '/usr/share/zoneinfo/UTC'
    notifies :run, 'execute[dpkg-reconfigure tzdata]', :immediately
  end

else
  raise "Don't know how to handle timezone for platform #{node['platform_family']}"
end

execute 'assert TZ is UTC' do
  command 'test "$(date +%Z)" = "UTC"'
end
