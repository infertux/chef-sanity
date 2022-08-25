control 'timezone-1' do
  title 'timezone is UTC'
  impact 1.0

  describe command('date +%Z') do
    its('stdout') { should eq "Etc/UTC\n" }
  end
end
