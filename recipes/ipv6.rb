unless node['sanity']['ipv6']
  require 'pathname'

  Pathname.glob('/proc/sys/net/ipv6/conf/*/disable_ipv6').map do |path|
    interface = path.to_s.split('/')[-2]

    sysctl "ipv6-#{interface}" do
      key "net.ipv6.conf.#{interface}.disable_ipv6"
      value 1
    end
  end
end
