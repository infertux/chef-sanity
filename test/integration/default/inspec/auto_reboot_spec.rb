control 'auto_reboot-1' do
  title 'reboot time is deterministic'
  impact 0.5

  case os.name
  when 'debian'
    # XXX: We don't actually care about the hostname here, this is just a
    # pre-condition for the next test. If this pre-condition fails then we
    # expect the next test to fail as well.
    describe sys_info do
      its('hostname') { should eq 'default-debian-stretch64' }
    end

    describe file('/etc/cron.d/auto_reboot') do
      its('content') { should match /\n44 20 25 / }
    end
  when 'centos'
    describe sys_info do
      its('hostname') { should eq 'default-centos-7.vagrantup.com' }
    end

    describe file('/etc/cron.d/auto_reboot') do
      its('content') { should match /\n55 19 4 / }
    end
  else
    raise "Don't know how to handle #{os.name}"
  end
end
