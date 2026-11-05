# Chef < 19.4.20 reloads sysctl settings with `sysctl -p`, which needs /etc/sysctl.conf, see recipes/sysctl.rb
chef_version = Gem::Version.new(command('/opt/cinc/bin/cinc-client --version').stdout[/\d+(\.\d+)+/] || '0')
chef_needs_sysctl_conf = chef_version < Gem::Version.new('19.4.20')

control 'sysctl-1' do
  title "/etc/sysctl.conf exists only when Chef needs it (Chef #{chef_version})"
  impact 1.0

  describe chef_version do
    it { should be > Gem::Version.new('0') } # make sure the version was detected
  end

  if chef_needs_sysctl_conf
    # the placeholder content proves the test image doesn't ship the file, so sanity created it
    describe file('/etc/sysctl.conf') do
      it { should be_file }
      its('owner') { should eq 'root' }
      its('content') { should eq "# placeholder for Chef < 19.4.20, see https://github.com/chef/chef/issues/15263\n" }
    end

    describe command('sysctl -p') do # what Chef < 19.4.20 runs
      its('exit_status') { should eq 0 }
    end
  else
    describe file('/etc/sysctl.conf') do
      it { should_not exist }
    end
  end
end

control 'sysctl-2' do
  title 'sysctl settings are applied and persisted'
  impact 1.0

  # node['sanity']['ipv6'] is false in .kitchen.yml
  describe kernel_parameter('net.ipv6.conf.all.disable_ipv6') do
    its('value') { should eq 1 }
  end

  describe file('/etc/sysctl.d/99-chef-net.ipv6.conf.all.disable_ipv6.conf') do
    its('content') { should match(/^net\.ipv6\.conf\.all\.disable_ipv6 = 1$/) }
  end

  # like recipes/os_hardening.rb, only where the kernel lets us change it
  if command('test -w /proc/sys/kernel/kptr_restrict').exit_status.zero?
    describe kernel_parameter('kernel.kptr_restrict') do
      its('value') { should eq 2 }
    end

    describe file('/etc/sysctl.d/99-chef-kernel.kptr_restrict.conf') do
      its('content') { should match(/^kernel\.kptr_restrict = 2$/) }
    end
  end
end

# after sysctl-2 since reloading would set the running values sysctl-2 checks convergence set
control 'sysctl-3' do
  title 'sysctl --system reloads the saved settings without errors'
  impact 1.0

  describe command('sysctl --system') do # what Chef >= 19.4.20 and systemd-sysctl run
    its('exit_status') { should eq 0 }
  end
end
