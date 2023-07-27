directory '/root/.ssh' do
  owner 'root'
  group 'root'
  mode '0700'
end

ssh_authorized_keys = Array(node.fetch('sanity').fetch('ssh').fetch('authorized_keys'))

file '/root/.ssh/authorized_keys' do
  owner 'root'
  group 'root'
  mode '0400'
  content ssh_authorized_keys.join("\n")
  not_if { ssh_authorized_keys.empty? }
end

node.override['ssh-hardening']['ssh']['server']['listen_to'] = \
  if node['sanity']['ipv4_reachable']
    node['ipaddress']
  else
    node['sanity']['ipv6'] ? ['0.0.0.0', '::'] : ['0.0.0.0']
  end

node.default['ssh-hardening']['network']['ipv6']['enable'] = node['sanity']['ipv6']

%w(client server).each do |component|
  # recommended crypto from https://github.com/dev-sec/ssh-baseline
  # and https://sshcheck.com/
  node.default['ssh-hardening']['ssh'][component]['cipher'] = 'aes256-ctr'
  node.default['ssh-hardening']['ssh'][component]['kex'] = 'curve25519-sha256,diffie-hellman-group-exchange-sha256'
  node.default['ssh-hardening']['ssh'][component]['mac'] = 'hmac-sha2-512'
end

node.default['ssh-hardening']['ssh']['server']['allow_root_with_key'] = true
node.default['ssh-hardening']['ssh']['server']['host_key_files'] = %w(/etc/ssh/ssh_host_ed25519_key)
node.default['ssh-hardening']['ssh']['use_privilege_separation'] = 'sandbox'

include_recipe 'ssh-hardening::default'
