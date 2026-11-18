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

# Default level so a wrapper can still change it, e.g. with a role or override attribute.
# On IPv6, sshd listens on :: rather than the primary address: SLAAC addresses come up late at boot and can change, and
# the firewall only accepts SSH over IPv6 from node['sanity']['firewall']['ssh_authorized_ips_v6'] anyway.
# sshd only exits when it can bind none of its addresses, so :: never stops it from listening on IPv4.
listen_to = [node['sanity']['ipv4_reachable'] ? node['ipaddress'] : '0.0.0.0']
listen_to << '::' if node['sanity']['ipv6']
node.default['ssh-hardening']['ssh']['server']['listen_to'] = listen_to

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

# Only the strongest algorithms, all offered by default by current OpenSSH clients (e.g. Arch Linux's):
# - kex: the two post-quantum hybrids, ML-KEM (FIPS 203, OpenSSH's default since 10.0) and Streamlined NTRU Prime (its
#   default from 9.0 to 9.9), which are different lattice constructions, plus X25519 alone for peers without them. A
#   hybrid is no weaker than X25519 even if its post-quantum half is broken.
# - ciphers: AEAD only. ChaCha20-Poly1305 is OpenSSH's default and fast without AES instructions, AES-256-GCM is fast
#   with them. The Terrapin attack on ChaCha20-Poly1305 is fixed by strict kex, which both ends have since OpenSSH 9.6.
# - MACs: never used with AEAD ciphers, which authenticate themselves, but the list can't be empty.
%w(client server).each do |component|
  node.default['ssh-hardening']['ssh'][component]['kex'] = 'mlkem768x25519-sha256,sntrup761x25519-sha512,curve25519-sha256'
  node.default['ssh-hardening']['ssh'][component]['cipher'] = 'chacha20-poly1305@openssh.com,aes256-gcm@openssh.com'
  node.default['ssh-hardening']['ssh'][component]['mac'] = 'hmac-sha2-512-etm@openssh.com'
end

node.default['ssh-hardening']['ssh']['server']['allow_root_with_key'] = true
node.default['ssh-hardening']['ssh']['server']['host_key_files'] = %w(/etc/ssh/ssh_host_ed25519_key)

include_recipe 'ssh-hardening::default'
