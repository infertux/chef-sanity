return if node['sanity']['email2telegram'].empty?

username = 'email2telegram'
script = '/usr/local/bin/email2telegram'

user username do
  system true
  shell '/usr/sbin/nologin'
end

template script do
  owner username
  group username
  mode '0500'
  variables(
    token: node['sanity']['email2telegram']['token'],
    chat_id: node['sanity']['email2telegram']['chat_id'],
  )
end

node.default['postfix']['master']['telegram'] = {
  active: true,
  order: 600,
  type: 'unix',
  unpriv: false,
  chroot: false,
  command: 'pipe',
  args: ["flags=X user=#{username} argv=#{script}"],
}

node.default['postfix']['main']['content_filter'] = 'telegram'
