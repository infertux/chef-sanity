# Inspired by https://gitlab.archlinux.org/archlinux/infrastructure/-/blob/master/roles/hardening/tasks/main.yml

sysctl 'kernel.kexec_load_disabled' do # https://sysctl-explorer.net/kernel/kexec_load_disabled/
  only_if { File.writable?('/proc/sys/kernel/kexec_load_disabled') } # unavailable on older kernels
  comment 'Disable kexec load'
  value 1
end

sysctl 'kernel.kptr_restrict' do # https://sysctl-explorer.net/kernel/kptr_restrict/
  only_if { File.writable?('/proc/sys/kernel/kptr_restrict') }
  comment 'Set restricted access to kernel pointers in proc fs'
  value 2
end

sysctl 'kernel.unprivileged_userns_clone' do
  only_if { File.writable?('/proc/sys/kernel/unprivileged_userns_clone') }
  comment 'Disable unprivileged userns'
  value 0
end

sysctl 'kernel.yama.ptrace_scope' do
  only_if { File.writable?('/proc/sys/kernel/yama/ptrace_scope') }
  comment 'Set ptrace scope, restrict ptrace to CAP_SYS_PTRACE'
  value 2
end

sysctl 'net.core.bpf_jit_harden' do # https://sysctl-explorer.net/net/core/bpf_jit_harden/
  only_if { File.writable?('/proc/sys/net/core/bpf_jit_harden') } # BPF JIT is unavailable when running inside non-host network namespace
  comment 'Enable BPF JIT hardening for all users'
  value 2
end

node.default['os-hardening']['network']['ipv6']['enable'] = node['sanity']['ipv6']

include_recipe 'os-hardening::default'
