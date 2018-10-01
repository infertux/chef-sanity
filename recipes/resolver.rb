# Cloudflare & OpenDNS
node.default['resolver']['nameservers'] = %w(
  1.1.1.1
  208.67.222.222
)

if node['sanity']['ipv6']
  node.default['resolver']['nameservers'] |= %w(
    2606:4700:4700::1111
    2620:0:ccc::2
  )
end

node.default['resolver']['domain'] = nil
node.default['resolver']['search'] = []

include_recipe 'resolver::default'
