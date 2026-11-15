# Run with Cinc's embedded Ruby: /opt/cinc/embedded/bin/ruby test/unit/firewall_test.rb
require 'minitest/autorun'
require 'chef'
require 'chef/client'
require 'chef/action_collection'
require 'tmpdir'
require 'fileutils'

require_relative '../../libraries/firewall_rebuild'

class FirewallTest < Minitest::Test
  ROOT = Dir.mktmpdir('sanity-firewall-test-')
  RULES = File.join(ROOT, 'nftables.d')
  CONFIG = File.join(ROOT, 'nftables.conf')
  CUSTOM = File.join(RULES, 'custom.nft')
  RELOADS = File.join(ROOT, 'reloads')
  REPO = File.expand_path('../..', __dir__)

  # Exercise Chef's real file resources and client lifecycle, redirecting paths
  # into a temporary directory. The verifier and service never touch a firewall.
  FileUtils.mkdir_p([RULES, File.join(ROOT, 'bin')])
  File.write(File.join(ROOT, 'bin/nft'), <<~'SH')
    #!/bin/sh
    content="$(for p in $(sed -n 's/^include "\(.*\)"/\1/p' "$3"); do cat "$p"; done)"
    printf '%s' "$content" | grep -q INVALID && exit 1
    if printf '%s' "$content" | grep -q 'add rule inet filter extra' && ! printf '%s' "$content" | grep -q 'add chain inet filter extra'; then exit 1; fi
    test "$(printf '%s' "$content" | grep -c 'create chain inet filter extra')" -le 1
  SH
  File.chmod(0755, File.join(ROOT, 'bin/nft'))
  ENV['PATH'] = "#{ROOT}/bin:#{ENV['PATH']}"
  Chef::Config[:node_name] = 'firewall-test'
  Chef::Config[:file_cache_path] = File.join(ROOT, 'cache')
  Chef::Config[:file_backup_path] = File.join(ROOT, 'backup')
  Chef::Log.level = :fatal

  %w(firewall nft).each do |name|
    source = File.read(File.join(REPO, "resources/#{name}.rb"))
                 .gsub('/etc/nftables.d', RULES).gsub('/etc/nftables.conf', CONFIG)
                 .gsub("owner 'root'", "owner #{Process.uid}").gsub("group 'root'", "group #{Process.gid}")
    path = File.join(ROOT, "#{name}.rb")
    File.write(path, source)
    Chef::Resource::LWRPBase.build_from_file('sanity', path, nil)
  end

  wrapper = File.join(ROOT, 'optional_wrapper.rb')
  File.write(wrapper, <<~'RESOURCE')
    unified_mode true
    property :ignored, [true, false], default: true
    property :delayed, [true, false], default: false
    default_action :run
    action :run do
      ruby_block 'optional child' do
        block { raise 'optional failure' }
        sensitive true
        ignore_failure new_resource.ignored
        action :nothing if new_resource.delayed
      end
      if new_resource.delayed
        ruby_block 'notify optional child' do
          block { true }
          notifies :run, 'ruby_block[optional child]', :delayed
        end
      end
    end
  RESOURCE
  Chef::Resource::LWRPBase.build_from_file('sanity', wrapper, nil)

  class ReloadService < Chef::Provider::Service
    def load_current_resource
      @current_resource = Chef::Resource::Service.new(new_resource.name)
      @current_resource.running(true)
      @current_resource
    end

    def reload_service
      ::File.open(RELOADS, 'a') { |file| file.puts('reload') }
    end
  end

  def setup
    FileUtils.rm_f(Dir.glob("#{RULES}/*") + [RELOADS])
    File.write(CUSTOM, "old rules\n")
    File.write(CONFIG, "include \"#{RULES}/*.nft\"\n")
    node = Chef::Node.new
    node.automatic['platform'] = 'debian'
    node.automatic['platform_version'] = '13'
    node.automatic['os'] = 'linux'
    @events = Chef::EventDispatch::Dispatcher.new
    @context = Chef::RunContext.new(node, {}, @events)
    @events.register(Chef::ActionCollection.new(@events, @context))
    @events.cookbook_compilation_start(@context)
    @recipe = Chef::Recipe.new('sanity', 'firewall_test', @context)
    @recipe.service('nftables') do
      provider ReloadService
      supports reload: true
      action :nothing
    end
  end

  def converge
    client = Chef::Client.new
    client.instance_variable_set(:@events, @events)
    client.send(:converge, @context)
  end

  def assert_preserved
    assert_equal "old rules\n", File.read(CUSTOM)
    refute_path_exists RELOADS
  end

  def test_collects_rules_and_reloads_once
    @recipe.sanity_firewall('default')
    @recipe.sanity_nft('new rule')
    @recipe.sanity_nft('another rule')
    converge
    assert_equal "new rule\nanother rule\n", File.read(CUSTOM)
    assert_equal ["reload\n"], File.readlines(RELOADS)
  end

  def test_unchanged_rules_do_not_reload_again
    @recipe.sanity_firewall('default')
    @recipe.sanity_nft('new rule')
    converge
    converge
    assert_equal "new rule\n", File.read(CUSTOM)
    assert_equal ["reload\n"], File.readlines(RELOADS)
  end

  def test_removing_the_last_rule_empties_the_file
    @recipe.sanity_firewall('default')
    converge
    assert_empty File.read(CUSTOM)
    assert_path_exists RELOADS
  end

  def test_rejected_rules_preserve_the_previous_file_and_fail_the_run
    @recipe.sanity_firewall('default')
    @recipe.sanity_nft('INVALID')
    assert_raises(Chef::Exceptions::ValidationFailed) { converge }
    assert_preserved
  end

  %w(before after).each do |position|
    define_method("test_failure_#{position}_rules_preserves_the_file") do
      @recipe.sanity_firewall('default')
      @recipe.sanity_nft('new rule') if position == 'after'
      @recipe.ruby_block('failure') { block { raise 'failure' } }
      @recipe.sanity_nft('new rule') if position == 'before'
      assert_raises(RuntimeError) { converge }
      assert_preserved
    end
  end

  [false, true].each do |sensitive_failure|
    define_method("test_ignored_root_failure_sensitive_#{sensitive_failure}") do
      @recipe.sanity_firewall('default')
      @recipe.sanity_nft('new rule')
      @recipe.ruby_block('optional') do
        block { raise 'optional' }
        ignore_failure true
        sensitive sensitive_failure
      end
      converge
      assert_equal "new rule\n", File.read(CUSTOM)
      assert_path_exists RELOADS
    end
  end

  [false, true].product([false, true], [false, true]).each do |ignored, parent_ignored, delayed|
    define_method("test_nested_failure_ignored_#{ignored}_parent_#{parent_ignored}_delayed_#{delayed}") do
      @recipe.sanity_firewall('default')
      @recipe.sanity_nft('new rule')
      @recipe.sanity_optional_wrapper('wrapper') do
        ignored ignored
        ignore_failure parent_ignored
        delayed delayed
        sensitive parent_ignored
      end
      if ignored || parent_ignored
        converge
        assert_equal "new rule\n", File.read(CUSTOM)
        assert_path_exists RELOADS
      else
        assert_raises(RuntimeError) { converge }
        assert_preserved
      end
    end
  end

  [false, true].each do |implicit|
    define_method("test_delayed_dependent_rules_with_implicit_firewall_#{implicit}") do
      @recipe.sanity_firewall('default') unless implicit
      @recipe.sanity_nft('add rule inet filter extra accept') { action :nothing }
      @recipe.sanity_nft('add chain inet filter extra') do
        priority 10
        action :nothing
      end
      @recipe.ruby_block('trigger') do
        block { true }
        notifies :create, 'sanity_nft[add rule inet filter extra accept]', :delayed
        notifies :create, 'sanity_nft[add chain inet filter extra]', :delayed
      end
      converge
      assert_equal "add chain inet filter extra\nadd rule inet filter extra accept\n", File.read(CUSTOM)
      assert_equal ["reload\n"], File.readlines(RELOADS)
    end
  end

  def test_alias_and_normalized_target_path
    File.write(CUSTOM, "create chain inet filter extra\n")
    @recipe.firewall('default') { path "#{RULES}/./custom.nft" }
    @recipe.sanity_nft('create chain inet filter extra')
    @recipe.sanity_nft('new rule')
    converge
    assert_equal "create chain inet filter extra\nnew rule\n", File.read(CUSTOM)
    assert_path_exists RELOADS
  end

  def test_multiple_firewalls_end_each_rule_with_a_newline
    @recipe.sanity_firewall('default')
    @recipe.firewall('web') { path File.join(RULES, 'web.nft') }
    @recipe.sanity_nft('new rule')
    @recipe.sanity_nft('web rule') { firewall_name 'web' }
    converge
    assert_equal "new rule\n", File.read(CUSTOM)
    assert_equal "web rule\n", File.read(File.join(RULES, 'web.nft'))
  end
end

Minitest.after_run { FileUtils.remove_entry(FirewallTest::ROOT) }
