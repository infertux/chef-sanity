package node['sanity']['packages']['purge'] do
  action :purge
end

package node['sanity']['packages']['install']

# CPU microcode security fixes come from the non-free-firmware component, see sanity::repositories
firmware = node['sanity']['repositories']['firmware']
firmware = node.dig('virtualization', 'role') != 'guest' if firmware.nil?
if firmware
  microcode = { 'GenuineIntel' => 'intel-microcode', 'AuthenticAMD' => 'amd64-microcode' }[node.dig('cpu', '0', 'vendor_id')]
  package microcode if microcode
end

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

# Warn about coredumps at the end of the run, instead of failing before the following recipes (e.g. the firewall) converge
# or counting as a change: sanity::systemd emails each new one
Chef.event_handler do
  on :run_completed do
    coredumps = Dir.glob('/var/lib/systemd/coredump/*')
    Chef::Log.warn("Found coredumps, see coredumpctl list: #{coredumps.join(' ')}") unless coredumps.empty?
  end
end
