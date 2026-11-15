unified_mode true

provides :firewall

property :name, String, default: 'default'
property :path, String, default: '/etc/nftables.d/custom.nft'
property :rules, Hash, default: {}

# Register once, including firewalls first created by a delayed sanity_nft.
def rebuild_after_converge
  return if @rebuild_handler

  @rebuild_handler = Sanity::FirewallRebuild.new(self)
  run_context.events.register(@rebuild_handler)
end

default_action :create

action :create do
  new_resource.rebuild_after_converge
end

action :rebuild do
  file new_resource.path do
    owner 'root'
    group 'root'
    mode '0400'
    # NOTE: the hash keys contain priorities used for sorting rules
    # each rule ends with a newline, since nft can't parse a file included after one that doesn't
    content new_resource.rules.sort.to_h.values.flatten.map { |rule| "#{rule}\n" }.join
    # Check the new rules with the rest of the ruleset before writing them, since nftables.service would fail to load
    # them at the next boot and leave no firewall: replace the current rules with them in /etc/nftables.conf's include
    verify do |path|
      target = ::File.expand_path(new_resource.path) # so that e.g. /etc/nftables.d/./custom.nft replaces custom.nft
      files = ::Dir.glob('/etc/nftables.d/*.nft').map { |file| ::File.expand_path(file) } | [target]
      includes = files.sort.map { |file| file == target ? path : file }
      config = ::File.read('/etc/nftables.conf').sub('include "/etc/nftables.d/*.nft"') { includes.map { |file| %(include "#{file}") }.join("\n") }
      ::Tempfile.create(%w(nftables .conf)) do |tempfile|
        tempfile.write(config)
        tempfile.close
        check = shell_out('nft', '--check', '-f', tempfile.path)
        Chef::Log.error("nft rejected the rules for #{new_resource.path}: #{check.stderr}") if check.error?
        !check.error?
      end
    end
    notifies :reload, 'service[nftables]', :immediately # delayed notifications have already finished
  end
end
