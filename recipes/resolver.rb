package 'systemd-resolved'

# IPv6 servers are left out here rather than in sanity's attributes, which are computed before the attribute files and
# recipes of wrapper cookbooks can disable IPv6 (an IPv6 address has at least two colons, an IPv4 one at most one)
dns_servers = Array(node['sanity']['resolver']['dns']).flat_map { |servers| servers.split(/[\s,]+/) }.reject(&:empty?) # also a string, like the resolver cookbook takes
dns_servers = dns_servers.reject { |server| server.count(':') >= 2 } unless node['sanity']['ipv6']

resolver_systemd_resolved_config '/etc/systemd/resolved.conf' do
  dns dns_servers
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
  only_if { ENV.key?('TEST_KITCHEN') }
  ignore_failure true # will fail if already unmounted
end

link '/etc/resolv.conf' do
  to '/run/systemd/resolve/stub-resolv.conf'
end

execute 'check that DNS is working' do
  command 'resolvectl query deb.debian.org'
  retries 3 # XXX: retry if needed since DNS resolution fails from time to time
end
