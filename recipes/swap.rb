include_recipe 'sanity::sysctl'

sysctl 'vm.swappiness' do
  not_if 'grep -a container= /proc/1/environ'
  value node['sanity']['swap']['swappiness']
end

swapfile = node['sanity']['swap']['swapfile']['path']

bash 'swapfile' do
  only_if { node['sanity']['swap']['swapfile']['size'].positive? }
  not_if "grep -q '^#{swapfile} ' /proc/swaps"
  user 'root'
  group 'root'
  umask '0077' # never let the swapfile be readable by other users, even briefly
  code <<~BASH
    #!/bin/bash

    set -euxo pipefail

    rm -f #{swapfile} # a leftover from a failed run may be world-readable and still open by another process
    dd if=/dev/zero of=#{swapfile} bs=1k count=#{node['sanity']['swap']['swapfile']['size']}M
    chmod 600 #{swapfile}
    mkswap #{swapfile}
    swapon #{swapfile}

    grep -q '^#{swapfile} ' /etc/fstab || echo "#{swapfile} swap swap auto 0 0" | tee -a /etc/fstab

    sysctl -w vm.swappiness=#{node['sanity']['swap']['swappiness']}
  BASH
end
