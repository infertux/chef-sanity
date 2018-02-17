node.normal['openssh']['server']['password_authentication'] = 'no'
node.normal['openssh']['server']['challenge_response_authentication'] = 'no'
node.normal['openssh']['server']['pubkey_authentication'] = 'yes'

include_recipe 'openssh::default'
