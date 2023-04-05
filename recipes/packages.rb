# Remove unwanted packages often installed by default
unwanted_packages = value_for_platform_family(
  %w(debian) => %w(bind9 sysstat),
  %w(rhel) => %w(centos-logos),
)

package unwanted_packages do
  action :purge
end

# Install useful packages
include_recipe 'sanity::tmux'

package %w(
  apt-forktracer
  cron
  curl
  htop
  rsync
  sudo
  vim
)

execute 'looking for non-Debian packages' do
  command 'apt-forktracer | sort'
end

bash 'looking for leftover configuration files' do
  user 'root'
  group 'root'
  code <<~BASH
    #!/bin/bash

    set -euo pipefail

    files=$(find /etc -name '*.dpkg-*' -o -name '*.ucf-*' -o -name '*.merge-error')
    echo "$files"

    #{'[ -z "$files" ]' if node['sanity']['packages']['fail_on_leftover_configuration_files']}
  BASH
end
