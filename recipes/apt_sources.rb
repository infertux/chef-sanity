apt_update do
  action :nothing
end

file '/etc/apt/sources.list' do
  owner 'root'
  group 'root'
  mode '0444'
  notifies :update, 'apt_update'
  content '# This file is managed by Chef, do not edit manually. Repositories are defined in sources.list.d'
end

codename = node['lsb']['codename'] || raise('no codename')

apt_repository codename do
  uri 'https://deb.debian.org/debian'
  distribution codename
  components %w(main)
end

apt_repository "#{codename}-updates" do
  uri 'https://deb.debian.org/debian'
  distribution "#{codename}-updates"
  components %w(main)
end

apt_repository "#{codename}-backports" do
  uri 'https://deb.debian.org/debian'
  distribution "#{codename}-backports"
  components %w(main)
  action node['sanity']['apt_sources']['backports'] ? :add : :remove
end

apt_repository 'testing' do
  uri 'https://deb.debian.org/debian'
  distribution 'testing'
  components %w(main)
  action node['sanity']['apt_sources']['testing'] ? :add : :remove
end

apt_repository 'security' do
  uri 'https://deb.debian.org/debian-security'
  distribution "#{codename}/updates"
  components %w(main)
end

file '/etc/apt/apt.conf.d/99default-release' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :update, 'apt_update'
  content 'APT::Default-Release "stable";'
end
