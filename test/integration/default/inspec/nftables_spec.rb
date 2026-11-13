control 'nftables-1' do
  title 'default policies are set properly'
  impact 1.0

  only_if('nftables is installed') do
    command('nft').exist?
  end

  describe command('nft list ruleset') do
    its('stdout') { should match /^table inet filter {/ }
    its('stdout') { should match /\stype filter hook input priority (filter|0); policy drop;\n/ }
    its('stdout') { should match /\stype filter hook forward priority (filter|0); policy drop;\n/ }
    its('stdout') { should match /\stype filter hook output priority (filter|0); policy accept;\n/ }
    its('stdout') { should match /ip saddr .+ tcp dport ({ 22 }|22) ct state new/ }
  end
end

control 'nftables-2' do
  title 'custom rules are rebuilt without any sanity_nft'
  impact 0.5

  # the suite declares no sanity_nft: custom.nft is still written, which is what empties it when the last one is removed
  describe file('/etc/nftables.d/custom.nft') do
    it { should be_file }
    its('content') { should eq '' }
  end
end
