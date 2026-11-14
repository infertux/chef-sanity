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
