control 'ssh-1' do
  title 'sshd is configured properly'
  impact 1.0

  describe sshd_config do
    its('PasswordAuthentication') { should eq 'no' }
    its('PubKeyAuthentication') { should eq 'yes' }
    its('X11Forwarding') { should eq 'no' }

    its('Ciphers') { should cmp('chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr') }
    its('KexAlgorithms') { should cmp('curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256') }
    its('MACs') { should cmp('hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com') }
  end
end

control 'ssh-2' do
  title 'sshd is listening'
  impact 1.0

  describe port(22) do
    it { should be_listening }
    its('protocols') { should cmp %w(tcp tcp6) }
    its('addresses') { should cmp %w(0.0.0.0 ::) }
    its('processes') { should cmp %w(sshd) }
  end
end

control 'ssh-3' do
  title 'authorized_keys is present'
  impact 1.0

  describe file('/root/.ssh/authorized_keys') do
    it { should be_file }
  end
end
