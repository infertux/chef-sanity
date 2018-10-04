node.default['openssh']['server']['password_authentication'] = 'no'
node.default['openssh']['server']['challenge_response_authentication'] = 'no'
node.default['openssh']['server']['pubkey_authentication'] = 'yes'

include_recipe 'openssh::default'

directory '/root/.ssh' do
  owner 'root'
  group 'root'
  mode '0700'
end

ssh_authorized_keys = node.fetch('sanity').fetch('ssh').fetch('authorized_keys')

file 'root/.ssh/authorized_keys' do
  owner 'root'
  group 'root'
  mode '0400'
  content ssh_authorized_keys.join("\n")
  not_if { ssh_authorized_keys.empty? }
end
