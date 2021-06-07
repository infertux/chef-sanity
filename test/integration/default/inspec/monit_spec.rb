control 'monit-1' do
  title 'monit is running'
  impact 0.5

  describe processes('monit') do
    it { should exist }
  end

  describe command('monit status') do
    its('stdout') { should match /^System '.+'$/ }
    its('stdout') { should match /^Filesystem '.+'$/ }
  end
end
