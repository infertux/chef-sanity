class Sanity
  # Chef emits converge_complete only after all delayed actions succeed. Failed
  # runs never reach it, so they cannot replace the live firewall with partial rules.
  #
  # One handler rebuilds every firewall of the run: each file is checked with the new rules of all of them, since a rule
  # can depend on another file (e.g. a chain created in custom.nft), and nftables is only reloaded once they're all
  # written, so it never loads a mix of old and new files.
  class FirewallRebuild < Chef::EventDispatch::Base
    attr_reader :firewalls

    def self.register(firewall)
      events = firewall.run_context.events
      handler = events.subscribers.find { |subscriber| subscriber.is_a?(self) }
      unless handler
        handler = new(firewall.run_context)
        events.register(handler)
      end
      handler.firewalls << firewall unless handler.firewalls.any? { |known| known.equal?(firewall) }
    end

    # the firewalls being rebuilt, whose new rules each file is checked with, or nil before the converge completes
    def self.rebuilding(run_context)
      handler = run_context.events.subscribers.find { |subscriber| subscriber.is_a?(self) }
      handler&.rebuilding
    end

    attr_reader :rebuilding

    def initialize(run_context)
      @run_context = run_context
      @firewalls = []
    end

    def converge_complete
      runner = @run_context.runner
      # A firewall's guards are evaluated here, once, so that the firewalls whose new rules are checked together are
      # exactly the ones written: Chef would evaluate them again for each rebuild, and could then skip one of them.
      @rebuilding = @firewalls.select { |firewall| (firewall.only_if + firewall.not_if).all?(&:continue?) }
      @rebuilding.each do |firewall|
        firewall.only_if.clear
        firewall.not_if.clear
      end
      updated = @rebuilding.map do |firewall|
        runner.run_action(firewall, :rebuild)
        firewall.updated_by_last_action?
      end
      runner.run_action(@run_context.resource_collection.find('service[nftables]'), :reload) if updated.any?
    ensure
      @rebuilding = nil
    end
  end
end
