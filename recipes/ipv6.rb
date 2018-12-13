require 'pathname'

Pathname.glob('/proc/sys/net/ipv6/conf/*/disable_ipv6').map do |path|
  interface = path.to_s.split('/')[-2]

  sysctl "ipv6-#{interface}" do
    action node['sanity']['ipv6'] ? :remove : :apply
    key "net.ipv6.conf.#{interface}.disable_ipv6"
    value 1
  end
end
