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
    its('stdout') { should match /ip saddr { [^}]+ } tcp dport (ssh|22) ct state new/ }
  end
end
