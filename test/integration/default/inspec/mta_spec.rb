control 'mta-1' do
  title 'MTA is listening'
  impact 1.0

  describe processes('postfix/sbin/master') do
    it { should exist }
  end

  describe port(25) do
    it { should be_listening }
    its('protocols') { should include 'tcp' }
    its('addresses') { should include '0.0.0.0' }
    its('processes') { should eq ['master'] }
  end
end
