control 'postfix-1' do
  title 'Postfix is listening'
  impact 1.0

  describe service('postfix') do
    it { should be_running }
  end

  describe processes('postfix/sbin/master') do
    it { should exist }
  end

  describe port(25) do
    it { should be_listening }
    its('protocols') { should cmp %w(tcp tcp6) }
    its('addresses') { should cmp %w(0.0.0.0 ::) }
    its('processes') { should cmp %w(master) }
  end
end

control 'postfix-2' do
  title 'Postfix is configured properly'
  impact 0.5

  describe command('postconf mynetworks') do
    its('stdout') { should match_array %w(127.0.0.0/8) }
  end

  describe command('postconf smtpd_use_tls') do
    its('stdout') { should eq 'yes!' }
  end
end
