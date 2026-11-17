unified_mode true

provides :firewall

property :name, String, default: 'default'
property :path, String, default: '/etc/nftables.d/custom.nft'
property :rules, Hash, default: {}

# Register once, including firewalls first created by a delayed sanity_nft.
def rebuild_after_converge
  Sanity::FirewallRebuild.register(self)
end

def target
  ::File.expand_path(path) # so that e.g. /etc/nftables.d/./custom.nft replaces custom.nft
end

# NOTE: the hash keys contain priorities used for sorting rules
# each rule ends with a newline, since nft can't parse a file included after one that doesn't
def content
  rules.sort.to_h.values.flatten.map { |rule| "#{rule}\n" }.join
end

default_action :create

action :create do
  new_resource.rebuild_after_converge
end

action :rebuild do
  firewalls = Sanity::FirewallRebuild.rebuilding(run_context)
  file new_resource.path do
    owner 'root'
    group 'root'
    mode '0400'
    content new_resource.content
    # Check the new rules with the rest of the ruleset before writing them, since nftables.service would fail to load
    # them at the next boot and leave no firewall: replace the current rules of every firewall with their new ones in
    # /etc/nftables.conf's include. Sanity::FirewallRebuild reloads nftables once they're all written.
    verify do |path|
      candidates = []
      begin
        pending = firewalls.reject { |firewall| firewall.target == new_resource.target }.to_h do |firewall|
          candidate = ::Tempfile.new(%w(firewall .nft))
          candidate.write(firewall.content)
          candidate.close
          candidates << candidate
          [firewall.target, candidate.path]
        end
        pending[new_resource.target] = path
        files = ::Dir.glob('/etc/nftables.d/*.nft').map { |file| ::File.expand_path(file) } | pending.keys
        includes = files.sort.map { |file| pending.fetch(file, file) }
        config = ::File.read('/etc/nftables.conf').sub('include "/etc/nftables.d/*.nft"') { includes.map { |file| %(include "#{file}") }.join("\n") }
        ::Tempfile.create(%w(nftables .conf)) do |tempfile|
          tempfile.write(config)
          tempfile.close
          check = shell_out('nft', '--check', '-f', tempfile.path)
          Chef::Log.error("nft rejected the rules for #{new_resource.path}: #{check.stderr}") if check.error?
          !check.error?
        end
      ensure
        candidates.each(&:unlink)
      end
    end
  end
end
