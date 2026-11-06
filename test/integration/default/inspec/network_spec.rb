control 'network-1' do
  title 'systemd-networkd took over the network from ifupdown'
  impact 1.0

  describe file('/etc/network/interfaces') do
    it { should_not exist }
  end

  describe service('systemd-networkd') do
    it { should be_enabled }
    it { should be_running }
  end

  # networking.service is a oneshot that stays "active (exited)": InSpec's be_running would never be true
  describe command('systemctl is-active networking.service') do
    its('stdout') { should eq "inactive\n" }
  end
end
