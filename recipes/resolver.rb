package 'systemd-resolved' do
  only_if { platform?('debian') && node['platform_version'].to_i >= 12 }
end

resolver_systemd_resolved_config '/etc/systemd/resolved.conf' do
  dns node['sanity']['resolver']['dns']
  dnssec node['sanity']['resolver']['dnssec']
  dns_over_tls 'opportunistic'
end

service 'systemd-resolved' do
  # XXX: make sure the service gets enabled since
  # resolver_systemd_resolved_config merely restarts it
  action :enable
end

# https://stackoverflow.com/questions/60549775/device-or-resource-busy-when-i-try-move-etc-resolv-conf-in-ubuntu18-04-how
execute 'umount -v /etc/resolv.conf' do
  only_if { ENV.fetch('TEST_KITCHEN', nil) }
  ignore_failure true # will fail if already unmounted
end

link '/etc/resolv.conf' do
  to '/run/systemd/resolve/stub-resolv.conf'
end

execute 'check that DNS is working' do
  command 'resolvectl query deb.debian.org'
  retries 3 # XXX: retry if needed since DNS resolution fails from time to time
end
