# Remove unwanted packages often installed by default
unwanted_packages = value_for_platform_family(
  %w(debian) => %w(nfs-common rpcbind bind9 sysstat),
  %w(rhel) => %w(centos-logos),
)

package unwanted_packages do
  action :purge
end

# Install useful packages
include_recipe 'sanity::tmux'
include_recipe 'vim::default'

package %w(
  cron
  curl
  htop
  sudo
)
