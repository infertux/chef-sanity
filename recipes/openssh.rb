node.default['openssh']['server']['password_authentication'] = 'no'
node.default['openssh']['server']['challenge_response_authentication'] = 'no'
node.default['openssh']['server']['pubkey_authentication'] = 'yes'

include_recipe 'openssh::default'
