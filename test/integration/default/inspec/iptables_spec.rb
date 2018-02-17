control 'iptables-1' do
  title 'incoming policies are set to DROP'
  impact 1.0

  describe command('iptables -nL INPUT') do
    its('stdout') { should include 'Chain INPUT (policy DROP)' }
  end

  describe command('ip6tables -nL INPUT') do
    its('stdout') { should include 'Chain INPUT (policy DROP)' }
  end

  describe command('iptables -nL FORWARD') do
    its('stdout') { should include 'Chain FORWARD (policy DROP)' }
  end

  describe command('ip6tables -nL FORWARD') do
    its('stdout') { should include 'Chain FORWARD (policy DROP)' }
  end

  describe command('iptables -nL OUTPUT') do
    its('stdout') { should include 'Chain OUTPUT (policy ACCEPT)' }
  end

  describe command('ip6tables -nL OUTPUT') do
    its('stdout') { should include 'Chain OUTPUT (policy ACCEPT)' }
  end
end
