node.default['os-hardening']['network']['ipv6']['enable'] = node['sanity']['ipv6']
# node.default['os-hardening']['network']['forwarding'] = false # TODO?
include_recipe 'os-hardening::default'
