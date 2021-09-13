case node['platform']
when 'centos'
  nil # NOOP
when 'debian'
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
  protocol = node['sanity']['repositories']['protocol']

  apt_repository codename do
    uri "#{protocol}://deb.debian.org/debian"
    distribution codename
    components %w(main)
  end

  apt_repository "#{codename}-updates" do
    uri "#{protocol}://deb.debian.org/debian"
    distribution "#{codename}-updates"
    components %w(main)
  end

  apt_repository "#{codename}-backports" do
    uri "#{protocol}://deb.debian.org/debian"
    distribution "#{codename}-backports"
    components %w(main)
    action node['sanity']['repositories']['backports'] ? :add : :remove
  end

  apt_repository 'testing' do
    uri "#{protocol}://deb.debian.org/debian"
    distribution 'testing'
    components %w(main)
    action node['sanity']['repositories']['testing'] ? :add : :remove
  end

  apt_repository 'security' do
    uri "#{protocol}://deb.debian.org/debian-security"
    # XXX: https://www.debian.org/releases/stable/amd64/release-notes/ch-information.en.html#security-archive
    distribution(node['platform_version'].to_i >= 11 ? "#{codename}-security" : "#{codename}/updates")
    components %w(main)
  end
else
  raise NotImplementedError, "Don't know how to handle repositories for #{node['platform']}"
end
