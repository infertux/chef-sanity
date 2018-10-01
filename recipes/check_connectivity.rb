execute 'ping 1.1.1.1 (no DNS)' do
  command 'ping -4 -c 1 -W 2 -q 1.1.1.1'
end

execute 'ping wikipedia over IPv4' do
  command 'ping -4 -c 1 -W 2 -q wikipedia.org'
end

execute 'ping wikipedia over IPv6' do
  command 'ping -6 -c 1 -W 2 -q wikipedia.org'
  only_if { node['sanity']['ipv6'] }
end

execute 'curl zx2c4.com/ip' do
  command 'curl -s https://www.zx2c4.com/ip'
end