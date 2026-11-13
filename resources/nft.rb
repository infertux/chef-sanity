unified_mode true

provides :nft

property :firewall_name, String, default: 'default'
property :priority, Integer, default: 100

default_action :create

action :create do
  with_run_context :root do
    # resources are found by the type they're declared with: sanity_firewall, as in sanity::firewall, or its firewall alias
    firewall = find_resource(:sanity_firewall, new_resource.firewall_name) ||
               find_resource(:firewall, new_resource.firewall_name) ||
               declare_resource(:sanity_firewall, new_resource.firewall_name)
    firewall.rules[new_resource.priority] ||= []
    firewall.rules[new_resource.priority] |= [new_resource.name] # its action can run more than once

    # a sanity_nft notified with a delayed action can converge after the firewall has been rebuilt: rebuild it again then
    if firewall.rebuilt
      firewall.queue_rebuild
    else
      firewall.delayed_action :rebuild
    end
  end
end
