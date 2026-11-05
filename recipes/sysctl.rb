# Chef < 19.4.20 reloads sysctl settings with `sysctl -p`, which fails when /etc/sysctl.conf doesn't exist,
# like on Debian 13 and Ubuntu 26.04: https://github.com/chef/chef/issues/15263
# Chef 19.4.20 uses `sysctl --system` instead, which doesn't need it: https://github.com/chef/chef/pull/16304
file '/etc/sysctl.conf' do
  content "# placeholder for Chef < 19.4.20, see https://github.com/chef/chef/issues/15263\n"
  action :create_if_missing
  only_if { Gem::Version.new(Chef::VERSION) < Gem::Version.new('19.4.20') }
end
