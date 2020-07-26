# Set TZ to UTC

case node['platform_family']
when 'debian', 'rhel'
  # XXX: `timedatectl show` is only available since Debian 10 so we fall back
  # to `timedatectl status` otherwise

  execute 'set-timezone UTC' do
    command 'timedatectl set-timezone UTC'
    not_if "timedatectl show 2>&1 | grep -qE '^Timezone=UTC$' || timedatectl status | grep -qE 'Time zone: UTC'"
  end

else
  raise NotImplementedError, "Don't know how to handle timezone for platform #{node['platform_family']}"
end
