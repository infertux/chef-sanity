control 'monit-1' do
  title 'monit is running'
  impact 0.5

  describe processes('monit') do
    it { should exist }
  end
end
