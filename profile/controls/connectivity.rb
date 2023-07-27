control 'connectivity-01' do
  impact 1.0
  title 'IPv4 connectivity (no DNS resolution)'

  only_if('GitHub Actions blocks ICMP') do
    ENV['GITHUB_ACTIONS'].nil?
  end

  describe command('ping -4 -c 2 -W 2 -q 1.1.1.1') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /2 packets transmitted, 2 received, 0% packet loss/ }
  end
end

control 'connectivity-02' do
  impact 1.0
  title 'IPv4 connectivity and DNS resolution'

  only_if('GitHub Actions blocks ICMP') do
    ENV['GITHUB_ACTIONS'].nil?
  end

  describe command('ping -4 -c 2 -W 2 -q wikipedia.org') do
    its('exit_status') { should eq 0 }
  end
end

control 'connectivity-03' do
  impact 0.8
  title 'IPv6 connectivity and DNS resolution'

  only_if('IPv6 disabled') do
    command('sysctl -b net.ipv6.conf.all.disable_ipv6').stdout == '0'
  end

  describe command('ping -6 -c 2 -W 2 -q wikipedia.org') do
    its('exit_status') { should eq 0 }
  end
end

control 'connectivity-04' do
  impact 1.0
  title 'curl can fetch URL'

  describe command('curl --head https://www.wikipedia.org/') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match %r{\AHTTP/2 200} }
  end
end

control 'connectivity-05' do
  impact 0.5
  title 'DNSSEC is working'

  describe command('resolvectl query brokendnssec.net') do
    its('exit_status') { should eq 1 }
    its('stdout') { should be_empty }
  end
end
