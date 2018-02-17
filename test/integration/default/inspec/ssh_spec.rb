control 'ssh-1' do
  title 'sshd is configured properly'
  impact 1.0

  describe sshd_config do
    its('PasswordAuthentication') { should eq 'no' }
    its('PubKeyAuthentication') { should eq 'yes' }
  end
end

control 'ssh-2' do
  title 'sshd is listening'
  impact 1.0

  describe port(22) do
    it { should be_listening }
    its('protocols') { should include 'tcp' }
    its('addresses') { should include '0.0.0.0' }
    its('processes') { should eq ['sshd'] }
  end
end

control 'ssh-3' do
  title 'authorized_keys is present'
  impact 1.0

  describe file('/root/.ssh/authorized_keys') do
    it { should be_file }
  end
end
