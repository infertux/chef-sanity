control 'repositories-1' do
  title 'sources.list is empty'
  impact 0.5

  describe command("grep -c -v '^#' /etc/apt/sources.list") do
    its('stdout') { should eq "0\n" }
  end
end

control 'repositories-2' do
  title 'non-free-firmware is only enabled on bare metal'
  impact 0.5

  # the default suite runs in a container, i.e. a virtualization guest
  describe file('/etc/apt/sources.list.d/trixie.list') do
    its('content') { should match(/ main$/) }
    its('content') { should_not match(/non-free-firmware/) }
  end

  describe package('intel-microcode') do
    it { should_not be_installed }
  end

  describe package('amd64-microcode') do
    it { should_not be_installed }
  end
end

control 'repositories-3' do
  title 'testing is disabled and not pinned by default'
  impact 0.5

  describe file('/etc/apt/sources.list.d/testing.list') do
    it { should_not exist }
  end

  describe file('/etc/apt/preferences.d/testing.pref') do
    it { should_not exist }
  end
end
