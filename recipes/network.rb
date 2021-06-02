directory '/etc/network' do
  owner 'root'
  group 'root'
  mode '0755'
end

file '/etc/network/interfaces' do
  owner 'root'
  group 'root'
  mode '0444'
  content <<~CONF
    # This file describes the network interfaces available on your system
    # and how to activate them. For more information, see interfaces(5).

    #{node['sanity']['network']['interfaces'].map { |_, config| config }.join("\n")}
  CONF
end
