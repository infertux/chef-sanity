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
