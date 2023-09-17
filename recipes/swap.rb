sysctl 'vm.swappiness' do
  not_if 'grep -a container= /proc/1/environ'
  value node['sanity']['swap']['swappiness']
end

swapfile = node['sanity']['swap']['swapfile']['path']

bash 'swapfile' do
  only_if { (node['sanity']['swap']['swapfile']['size']).positive? }
  creates swapfile
  user 'root'
  group 'root'
  code <<~BASH
    #!/bin/bash

    set -euxo pipefail

    dd if=/dev/zero of=#{swapfile} bs=1k count=#{node['sanity']['swap']['swapfile']['size']}M
    chmod 600 #{swapfile}
    mkswap #{swapfile}
    swapon #{swapfile}

    echo "#{swapfile} swap swap auto 0 0" | tee -a /etc/fstab

    sysctl -w vm.swappiness=#{node['sanity']['swap']['swappiness']}
  BASH
end
