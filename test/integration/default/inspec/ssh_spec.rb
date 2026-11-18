control 'ssh-1' do
  title 'sshd is configured properly'
  impact 1.0

  describe sshd_config do
    its('PasswordAuthentication') { should eq 'no' }
    its('PubKeyAuthentication') { should eq 'yes' }
    its('X11Forwarding') { should eq 'no' }
  end
end

control 'ssh-2' do
  title 'sshd is listening on IPv4 only'
  impact 1.0

  describe port(22) do
    it { should be_listening }
    its('protocols') { should cmp %w(tcp) }
    its('addresses') { should cmp %w(0.0.0.0) }
  end
end

control 'ssh-3' do
  title 'authorized_keys is present'
  impact 1.0

  describe file('/root/.ssh/authorized_keys') do
    it { should be_file }
    its('content') { should eq 'ssh-ed25519 AAAA+testkey test@example.net' }
  end
end

control 'ssh-4' do
  title 'sshd is restarted until it can bind its addresses'
  impact 1.0

  # --all shows RestartPreventExitStatus even though it's empty
  describe command('systemctl show --all --property=Restart,RestartPreventExitStatus,RestartUSec,RestartSteps,RestartMaxDelayUSec ssh.service') do
    its('stdout') { should match /^Restart=on-failure$/ }
    its('stdout') { should match /^RestartPreventExitStatus=$/ }
    its('stdout') { should match /^RestartUSec=5s$/ }
    its('stdout') { should match /^RestartSteps=8$/ }
    its('stdout') { should match /^RestartMaxDelayUSec=5min$/ }
  end
end

control 'ssh-5' do
  title 'sshd and ssh only allow modern crypto'
  impact 1.0

  kex = 'mlkem768x25519-sha256,sntrup761x25519-sha512,curve25519-sha256'
  ciphers = 'chacha20-poly1305@openssh.com,aes256-gcm@openssh.com'
  macs = 'hmac-sha2-512-etm@openssh.com'

  # sshd -T and ssh -G print the configuration in effect, and fail on algorithms OpenSSH doesn't know.
  # sshd only offers host key algorithms it has a key for, so the ed25519 host key alone limits them to ssh-ed25519.
  describe command('sshd -T') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /^kexalgorithms #{Regexp.escape(kex)}$/ }
    its('stdout') { should match /^ciphers #{Regexp.escape(ciphers)}$/ }
    its('stdout') { should match /^macs #{Regexp.escape(macs)}$/ }
    its('stdout') { should match %r{^hostkey /etc/ssh/ssh_host_ed25519_key$} }
    its('stdout') { should_not match %r{^hostkey (?!/etc/ssh/ssh_host_ed25519_key$)} }
  end

  describe command('ssh -G localhost') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /^kexalgorithms #{Regexp.escape(kex)}$/ }
    its('stdout') { should match /^ciphers #{Regexp.escape(ciphers)}$/ }
    its('stdout') { should match /^macs #{Regexp.escape(macs)}$/ }
  end
end
