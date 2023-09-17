control 'repositories-1' do
  title 'sources.list is empty'
  impact 0.5

  case os.name
  when 'debian'
    describe command("grep -c -v '^#' /etc/apt/sources.list") do
      its('stdout') { should eq "0\n" }
    end
  when 'ubuntu'
    describe command("grep -c -v '^#' /etc/apt/sources.list") do
      its('stdout') { should_not eq "0\n" }
    end
  else
    raise "Unknown OS name #{os.name.inspect}"
  end
end
