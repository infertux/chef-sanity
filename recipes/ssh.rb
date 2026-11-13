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

node.override['ssh-hardening']['ssh']['server']['listen_to'] =
  if node['sanity']['ipv4_reachable']
    node['ipaddress']
  else
    node['sanity']['ipv6'] ? ['0.0.0.0', '::'] : ['0.0.0.0']
  end

node.default['ssh-hardening']['network']['ipv6']['enable'] = node['sanity']['ipv6']

# At boot, network.target doesn't wait for the addresses: sshd can start before systemd-networkd has the primary address
# it listens on, fail to bind it and exit with 255, which Debian's ssh.service doesn't restart. Restart it until it
# binds instead. Every 5 seconds stays under systemd's default start limit (5 starts in 10 seconds), so it never gives up.
# Each failed start also emails root through sanity::systemd's OnFailure handler, so the delay grows to 5 minutes.
# (Waiting for network-online.target would delay sshd by systemd-networkd-wait-online's 2 minutes whenever a link it
# waits for never comes up, e.g. an unplugged NIC.)
directory '/etc/systemd/system/ssh.service.d'

systemd_unit 'ssh.service.d/sanity.conf' do
  content <<~SYSTEMD
    [Service]
    Restart=on-failure
    RestartPreventExitStatus=
    RestartSec=5s
    RestartSteps=8
    RestartMaxDelaySec=5min
  SYSTEMD

  verify false # XXX: drop-ins fail verification, like service.d/10-all.conf in sanity::systemd
  action :create
end

%w(client server).each do |component|
  # recommended crypto from https://github.com/dev-sec/ssh-baseline
  # and https://sshcheck.com/
  node.default['ssh-hardening']['ssh'][component]['cipher'] = 'aes256-ctr'
  node.default['ssh-hardening']['ssh'][component]['kex'] = 'curve25519-sha256,diffie-hellman-group-exchange-sha256'
  node.default['ssh-hardening']['ssh'][component]['mac'] = 'hmac-sha2-512'
end

node.default['ssh-hardening']['ssh']['server']['allow_root_with_key'] = true
node.default['ssh-hardening']['ssh']['server']['host_key_files'] = %w(/etc/ssh/ssh_host_ed25519_key)

include_recipe 'ssh-hardening::default'
