class Sanity
  # Chef emits converge_complete only after all delayed actions succeed. Failed
  # runs never reach it, so they cannot replace the live firewall with partial rules.
  class FirewallRebuild < Chef::EventDispatch::Base
    def initialize(firewall)
      @firewall = firewall
    end

    def converge_complete
      @firewall.run_context.runner.run_action(@firewall, :rebuild)
    end
  end
end
