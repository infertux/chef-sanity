unified_mode true

provides :firewall

property :name, String, default: 'default'
property :path, String, default: '/etc/nftables.d/custom.nft'
property :rules, Hash, default: {}

default_action :create

action :create do
  # nil
end

action :rebuild do
  file new_resource.path do
    owner 'root'
    group 'root'
    mode '0400'
    # NOTE: the hash keys contain priorities used for sorting rules
    content new_resource.rules.sort.to_h.values.flatten.join("\n")
    notifies :restart, 'service[nftables]'
  end
end
