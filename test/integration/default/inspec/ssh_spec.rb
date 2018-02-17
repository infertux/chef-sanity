control 'ssh-1' do
  title 'authorized_keys is present'
  impact 1.0

  describe file('/root/.ssh/authorized_keys') do
    it { should be_file }
  end
end
