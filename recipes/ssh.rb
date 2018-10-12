node.default['openssh']['server']['password_authentication'] = 'no'
node.default['openssh']['server']['challenge_response_authentication'] = 'no'
node.default['openssh']['server']['pubkey_authentication'] = 'yes'
node.default['openssh']['server']['x11_forwarding'] = 'no'

# XXX: Check https://cipherli.st/ for latest recommendations
node.default['openssh']['server']['ciphers'] = 'chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr'
node.default['openssh']['server']['kex_algorithms'] = 'curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256'
node.default['openssh']['server']['m_a_cs'] = 'hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com'

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
