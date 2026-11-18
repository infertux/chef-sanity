package node['sanity']['packages']['purge'] do
  action :purge
end

package node['sanity']['packages']['install']

# CPU microcode security fixes come from the non-free-firmware component, see sanity::repositories
firmware = node['sanity']['repositories']['firmware']
firmware = node.dig('virtualization', 'role') != 'guest' if firmware.nil?
if firmware
  microcode = { 'GenuineIntel' => 'intel-microcode', 'AuthenticAMD' => 'amd64-microcode' }[node.dig('cpu', '0', 'vendor_id')]
  package microcode if microcode
end

include_recipe 'sanity::tmux'

leftovers = -> { Dir.glob('/etc/**/*.{dpkg-*,ucf-*,merge-error}', File::FNM_DOTMATCH) }

ruby_block 'failing on leftover configuration files' do
  block { raise "Found leftover configuration files: #{leftovers.call.join(' ')}" }
  only_if { node['sanity']['packages']['fail_on_leftover_configuration_files'] && leftovers.call.any? }
end

# Warn at the end of the run, instead of failing before the following recipes (e.g. the firewall) converge or counting
# as changes: sanity::systemd also emails each new coredump
Chef.event_handler do
  on :run_completed do
    {
      'coredumps, see coredumpctl list' => Dir.glob('/var/lib/systemd/coredump/*'),
      'leftover configuration files' => leftovers.call,
      'non-Debian packages' => File.exist?('/usr/bin/apt-forktracer') ? `apt-forktracer`.lines(chomp: true).sort : [],
    }.each { |what, found| Chef::Log.warn("Found #{what}: #{found.join(', ')}") unless found.empty? }
  end
end
