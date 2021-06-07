resolver_systemd_resolved_config '/etc/systemd/resolved.conf' do
  dns node['sanity']['resolver']['dns']
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
