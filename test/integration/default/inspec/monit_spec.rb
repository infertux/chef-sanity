control 'monit-1' do
  title 'monit is running'
  impact 0.5

  describe processes('monit') do
    it { should exist }
  end

  describe command('monit status') do
    its('stderr') { should be_empty }
    its('stdout') { should match /^System '.+'$/ }
    its('stdout') { should match /^Filesystem '.+'$/ }
  end

  describe port(2812) do
    it { should_not be_listening }
  end

  describe file('/run/monit.sock') do
    it { should be_socket }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
  end
end
