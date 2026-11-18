raise NotImplementedError, "Don't know how to handle repositories for #{node['platform']}" unless platform?('debian')

apt_update do
  action :nothing
end

file '/etc/apt/sources.list.d/debian.sources' do
  action :delete
end

file '/etc/apt/sources.list' do
  owner 'root'
  group 'root'
  mode '0444'
  notifies :update, 'apt_update'
  content '# This file is managed by Chef, do not edit manually. Repositories are defined in sources.list.d'
end

codename = node['lsb']['codename'] || raise('no codename')
protocol = node['sanity']['repositories']['protocol']
firmware = node['sanity']['repositories']['firmware']
firmware = node.dig('virtualization', 'role') != 'guest' if firmware.nil?
repo_components = %w(main)
repo_components << 'non-free-firmware' if firmware

apt_repository codename do
  uri "#{protocol}://deb.debian.org/debian"
  distribution codename
  components repo_components
  signed_by false
end

apt_repository "#{codename}-updates" do
  uri "#{protocol}://deb.debian.org/debian"
  distribution "#{codename}-updates"
  components repo_components
  signed_by false
end

apt_repository "#{codename}-backports" do
  uri "#{protocol}://deb.debian.org/debian"
  distribution "#{codename}-backports"
  components repo_components
  signed_by false
  action node['sanity']['repositories']['backports'] ? :add : :remove
end

apt_repository 'testing' do
  uri "#{protocol}://deb.debian.org/debian"
  distribution 'testing'
  components repo_components
  signed_by false
  action node['sanity']['repositories']['testing'] ? :add : :remove
end

# Without a pin, testing would get the same priority (500) as stable and its newer versions would win, so
# unattended-upgrades would gradually move the whole machine to testing.
apt_preference 'testing' do
  glob '*'
  pin 'release a=testing'
  pin_priority '100'
  action node['sanity']['repositories']['testing'] ? :add : :remove
end

apt_repository 'security' do
  uri "#{protocol}://deb.debian.org/debian-security"
  distribution "#{codename}-security"
  components repo_components
  signed_by false
end
