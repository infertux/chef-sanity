control 'resolver-1' do
  title 'systemd-resolved only uses IPv4 DNS servers' # since IPv6 is disabled in .kitchen.yml
  impact 0.5

  describe command('systemd-analyze cat-config systemd/resolved.conf') do
    its('stdout') { should match /^DNS=.*\b1\.1\.1\.1\b/ }
    its('stdout') { should_not match /^DNS=.*:.*:/ }
  end
end
