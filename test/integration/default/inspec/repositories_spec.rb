control 'repositories-1' do
  title 'sources.list is empty'
  impact 0.5

  if os.debian?
    describe command("grep -c -v '^#' /etc/apt/sources.list") do
      its('stdout') { should eq "0\n" }
    end
  end
end

control 'repositories-2' do
  title 'Backports are enabled on Buster to get Monit'
  impact 0.5

  if os.debian?
    case os.release.to_i
    when 10
      describe file('/etc/apt/sources.list.d/buster-backports.list') do
        it { should exist }
      end
    when 11
      describe file('/etc/apt/sources.list.d/bullseye-backports.list') do
        it { should_not exist }
      end
    else
      raise "Unknown release #{os.release.inspect}"
    end
  end
end
