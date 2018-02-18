node.normal['cronapt']['mailto'] = node['sanity']['aliases']['root']
node.normal['cronapt']['mailon'] = 'upgrade'
node.normal['cronapt']['hourly'] = true
node.normal['cronapt']['enable_upgrade'] = true
node.normal['cronapt']['force_confold'] = true

include_recipe 'cronapt::default'
