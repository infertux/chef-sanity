unified_mode true

provides :firewall

property :name, String, default: 'default'
property :path, String, default: '/etc/nftables.d/custom.nft'
property :rules, Hash, default: {}

attr_accessor :rebuilt # whether the rebuild action has written the rules, see sanity_nft

# Move the rebuild to the end of the delayed actions. Chef doesn't queue a delayed action again while it's in the queue,
# which it stays in after it has run, so the queued one is disabled first.
def queue_rebuild
  run_context.delayed_actions.each do |notification|
    notification.action = :nothing if notification.resource.equal?(self) && notification.action == :rebuild
  end
  delayed_action :rebuild
end

default_action :create

action :create do
  # nil
end

action :rebuild do
  root = run_context.root_run_context
  # A sanity_nft notified with a delayed action only adds its rules when that action runs: rebuild after it, since nft
  # could reject an incomplete set of rules
  queued = root.delayed_actions.drop_while { |n| !(n.resource.equal?(new_resource) && n.action == :rebuild) }.drop(1)
  pending = queued.any? { |n| n.action != :nothing && n.resource.respond_to?(:firewall_name) && n.resource.firewall_name == new_resource.name }
  # Chef also runs delayed actions when the run fails, and a sanity_nft that hasn't converged hasn't added its rules:
  # only rebuild once every resource has converged, otherwise the current rules would be lost. Firewalls are left out
  # since they don't add rules, and one declared by a delayed sanity_nft is never converged.
  # Only top-level actions are checked: a failure in a custom resource's child that isn't ignored also fails its parent.
  # Chef replaces sensitive resources in its action records with blank copies, which lose ignore_failure, so it's also
  # read from the resources themselves.
  ignored = lambda do |failed_resource|
    failed_resource.ignore_failure || root.resource_collection.all_resources.any? do |resource|
      resource.ignore_failure && resource.instance_of?(failed_resource.class) && resource.name == failed_resource.name
    end
  end
  failed = root.action_collection&.any? { |record| record.nesting_level.zero? && record.status == :failed && !ignored.call(record.new_resource) }
  unconverged = root.resource_collection.all_resources.reject { |resource| resource.is_a?(new_resource.class) || resource.executed_by_runner }
  if pending
    new_resource.queue_rebuild
  elsif failed || unconverged.any?
    Chef::Log.warn("Keeping #{new_resource.path} as it is since the Chef run failed before every sanity_nft converged")
  else
    new_resource.rebuilt = true
    file new_resource.path do
      owner 'root'
      group 'root'
      mode '0400'
      # NOTE: the hash keys contain priorities used for sorting rules
      content new_resource.rules.sort.to_h.values.flatten.join("\n")
      # Check the new rules with the rest of the ruleset before writing them, since nftables.service would fail to load
      # them at the next boot and leave no firewall: replace the current rules with them in /etc/nftables.conf's include
      verify do |path|
        includes = (::Dir.glob('/etc/nftables.d/*.nft') | [new_resource.path]).sort.map { |file| file == new_resource.path ? path : file }
        config = ::File.read('/etc/nftables.conf').sub('include "/etc/nftables.d/*.nft"') { includes.map { |file| %(include "#{file}") }.join("\n") }
        ::Tempfile.create(%w(nftables .conf)) do |tempfile|
          tempfile.write(config)
          tempfile.close
          check = shell_out('nft', '--check', '-f', tempfile.path)
          Chef::Log.error("nft rejected the rules for #{new_resource.path}: #{check.stderr}") if check.error?
          !check.error?
        end
      end
      notifies :reload, 'service[nftables]', :immediately # a delayed reload might already have run, see sanity_nft
    end
  end
end
