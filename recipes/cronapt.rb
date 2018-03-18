node.default['cronapt']['mailto'] = node['sanity']['aliases']['root']
node.default['cronapt']['mailon'] = 'upgrade'
node.default['cronapt']['hourly'] = true
node.default['cronapt']['enable_upgrade'] = true
node.default['cronapt']['force_confold'] = true

include_recipe 'cronapt::default'
