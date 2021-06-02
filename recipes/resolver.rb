# Cloudflare & OpenDNS
ips = %w(1.1.1.1 208.67.222.222)
ips |= %w(2606:4700:4700::1111 2620:119:35::35) if node['sanity']['ipv6']

resolver_systemd_resolved_config '/etc/systemd/resolved.conf' do
  dns ips
  dnssec true
  dns_over_tls 'opportunistic'
end

service 'systemd-resolved' do
  # XXX: make sure the service gets enabled since
  # resolver_systemd_resolved_config merely restarts it
  action :enable
end

link '/etc/resolv.conf' do
  to '/run/systemd/resolve/stub-resolv.conf'
  ignore_failure !ENV['TEST_KITCHEN'].nil?
end
