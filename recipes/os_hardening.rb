# Inspired by https://gitlab.archlinux.org/archlinux/infrastructure/-/blob/master/roles/hardening/tasks/main.yml

sysctl 'kernel.kexec_load_disabled' do # https://sysctl-explorer.net/kernel/kexec_load_disabled/
  comment 'Disable kexec load'
  value 1
end

sysctl 'kernel.kptr_restrict' do # https://sysctl-explorer.net/kernel/kptr_restrict/
  comment 'Set restricted access to kernel pointers in proc fs'
  value 2
end

sysctl 'kernel.unprivileged_userns_clone' do
  comment 'Disable unprivileged userns'
  value 0
end

sysctl 'kernel.yama.ptrace_scope' do
  comment 'Set ptrace scope, restrict ptrace to CAP_SYS_PTRACE'
  value 2
end

sysctl 'net.core.bpf_jit_harden' do # https://sysctl-explorer.net/net/core/bpf_jit_harden/
  ignore_failure true # BPF JIT is unavailable when running inside non-host network namespace
  comment 'Enable BPF JIT hardening for all users'
  value 2
end

node.default['os-hardening']['network']['ipv6']['enable'] = node['sanity']['ipv6']

include_recipe 'os-hardening::default'
