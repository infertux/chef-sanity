unified_mode true

provides :nft

property :firewall_name, String, default: 'default'
property :priority, Integer, default: 100

default_action :create

action :create do
  with_run_context :root do
    edit_resource(:firewall, new_resource.firewall_name) do |rule|
      rules[rule.priority] ||= []
      rules[rule.priority] << rule.name

      delayed_action :rebuild
    end
  end
end
