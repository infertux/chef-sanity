package node['sanity']['packages']['purge'] do
  action :purge
end

package node['sanity']['packages']['install']

include_recipe 'sanity::tmux'

execute 'looking for non-Debian packages' do
  command 'apt-forktracer | sort'
  only_if 'which apt-forktracer'
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

execute 'looking for coredumps' do
  # XXX: fail the Chef run if coredumps are found
  command 'test -z "$(ls -A /var/lib/systemd/coredump)"'
end
