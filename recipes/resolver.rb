# https://en.wikipedia.org/wiki/OpenDNS
node.normal['resolver']['nameservers'] = %w(
  208.67.222.222
  208.67.220.220
  2620:0:ccc::2
)

node.normal['resolver']['domain'] = nil
node.normal['resolver']['search'] = nil

include_recipe 'resolver::default'
