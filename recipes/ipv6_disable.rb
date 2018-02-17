require 'pathname'

lines = Pathname.glob('/proc/sys/net/ipv6/conf/*/disable_ipv6').map do |path|
  interface = path.to_s.split('/')[-2]
  "net.ipv6.conf.#{interface}.disable_ipv6=1"
end

lines.each { |line| execute "sysctl -w #{line}" }

file '/etc/sysctl.d/20-ipv6.conf' do
  owner 'root'
  group 'root'
  mode '0400'
  content lines.join("\n")
end
