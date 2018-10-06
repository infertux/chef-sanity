control 'apt_sources-1' do
  title 'sources.list is empty'
  impact 0.5

  describe command("grep -c -v '^#' /etc/apt/sources.list") do
    its('stdout') { should eq "0\n" }
  end
end
