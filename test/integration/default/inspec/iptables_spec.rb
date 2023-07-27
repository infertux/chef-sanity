control 'iptables-1' do
  title 'default policies are set properly'
  impact 1.0

  only_if('iptables is installed') do
    command('iptables').exist?
  end

  describe command('iptables -nL INPUT') do
    its('stdout') { should include 'Chain INPUT (policy DROP)' }
  end

  describe command('iptables -nL FORWARD') do
    its('stdout') { should include 'Chain FORWARD (policy DROP)' }
  end

  describe command('iptables -nL OUTPUT') do
    its('stdout') { should include 'Chain OUTPUT (policy ACCEPT)' }
  end

  describe iptables do
    it { should have_rule('-A INPUT -i lo -j ACCEPT') }
  end
end
