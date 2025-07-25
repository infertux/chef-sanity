case node['platform']
when 'debian'
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

  apt_repository codename do
    uri "#{protocol}://deb.debian.org/debian"
    distribution codename
    components %w(main)
    signed_by false
  end

  apt_repository "#{codename}-updates" do
    uri "#{protocol}://deb.debian.org/debian"
    distribution "#{codename}-updates"
    components %w(main)
    signed_by false
  end

  apt_repository "#{codename}-backports" do
    uri "#{protocol}://deb.debian.org/debian"
    distribution "#{codename}-backports"
    components %w(main)
    signed_by false
    action node['sanity']['repositories']['backports'] ? :add : :remove
  end

  apt_repository 'testing' do
    uri "#{protocol}://deb.debian.org/debian"
    distribution 'testing'
    components %w(main)
    signed_by false
    action node['sanity']['repositories']['testing'] ? :add : :remove
  end

  apt_repository 'security' do
    uri "#{protocol}://deb.debian.org/debian-security"
    distribution "#{codename}-security"
    components %w(main)
    signed_by false
  end
when 'ubuntu'
  # NOOP
else
  raise NotImplementedError, "Don't know how to handle repositories for #{node['platform']}"
end
