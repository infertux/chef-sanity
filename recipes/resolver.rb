# https://en.wikipedia.org/wiki/OpenDNS
node.default['resolver']['nameservers'] = %w(
  208.67.222.222
  208.67.220.220
  2620:0:ccc::2
)

node.default['resolver']['domain'] = nil
node.default['resolver']['search'] = []

include_recipe 'resolver::default'
