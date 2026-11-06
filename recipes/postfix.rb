settings = {
  # https://www.postfix.org/COMPATIBILITY_README.html
  'compatibility_level' => '3.6',
  'inet_interfaces' => 'all',
  'inet_protocols' => node['sanity']['postfix']['inet_protocols'] || (node['sanity']['ipv6'] ? 'all' : 'ipv4'),

  # TLS options
  # generated 2026-11-05, TLSRef Guideline v6.0, Postfix 3.10.13, OpenSSL 3.5.7, modern config
  # https://configurator.tlsref.org/#server=postfix&version=3.10.13&config=modern&openssl=3.5.7&guideline=6.0
  # https://security.stackexchange.com/questions/200176/is-tls-preempt-cipherlist-yes-in-postfix-a-good-idea-nowadays
  'tls_preempt_cipherlist' => 'no',
  'tls_eecdh_auto_curves' => 'X25519MLKEM768 X25519 prime256v1 secp384r1',
  'tls_ffdhe_auto_groups' => '',

  # smtp(d)_use_tls are deprecated in favor of smtp(d)_tls_security_level: nil removes the cookbook's defaults from main.cf,
  # so we have to set the settings the cookbook derives from them ourselves
  'smtp_use_tls' => nil,
  'smtpd_use_tls' => nil,

  # TLS client options (smtp_*)
  'smtp_tls_security_level' => 'verify', # stricter than the guideline's "may"
  # the guideline's >=TLSv1.3 could make emails bounce from servers which don't support TLS 1.3 yet
  'smtp_tls_protocols' => '>=TLSv1.2',
  'smtp_tls_mandatory_protocols' => '>=TLSv1.2',
  'smtp_tls_note_starttls_offer' => 'yes',
  'smtp_tls_CAfile' => '/etc/ssl/certs/ca-certificates.crt',
  'smtp_tls_session_cache_database' => 'btree:${data_directory}/smtp_scache',

  # TLS server options (smtpd_*)
  'smtpd_tls_auth_only' => 'yes',
  'smtpd_tls_security_level' => 'may',
  'smtpd_tls_protocols' => '>=TLSv1.3',
  'smtpd_tls_mandatory_protocols' => '>=TLSv1.3',
  'smtpd_tls_session_cache_database' => 'btree:${data_directory}/smtpd_scache',
  # XXX: If smtpd is going to be used, proper certificates should be generated and
  # set with smtpd_tls_cert_file and smtpd_tls_key_file (see README)
  'smtpd_tls_cert_file' => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  'smtpd_tls_key_file' => '/etc/ssl/private/ssl-cert-snakeoil.key',
}

relay = node['sanity']['postfix']['relay']
unless relay.empty?
  settings['relayhost'] = relay.fetch('host')
  settings['smtp_sasl_auth_enable'] = 'yes' if relay['username'] # also makes the postfix resource configure SASL
  # relays usually only accept their own address as sender: send everything (root@fqdn, monit@fqdn, etc.) from root_email
  settings['sender_canonical_maps'] = "static:#{node['sanity']['root_email']}" unless node['sanity']['root_email'].empty?
end

# None of our master.cf services run chrooted, so don't let Debian copy files into the chroot (/var/spool/postfix/etc):
# it copies /etc/resolv.conf with its owner (systemd-resolve), and "postfix check" warns that it's not owned by root.
# XXX: chrooted services would need SYNC_CHROOT to get these files (see /usr/share/doc/postfix/README.Debian.gz)
file '/etc/default/postfix' do
  content "SYNC_CHROOT=\n" # empty disables syncing
  mode '0644'
end

postfix 'default' do
  mail_type 'master'
  main_settings settings

  # add missing entry for retry service in master.cf
  master_settings(
    'retry' => {
      'active' => true,
      'order' => 900, # should be last, see postfix_default_master_settings in https://github.com/sous-chefs/postfix/blob/main/libraries/helpers.rb
      'type' => 'unix',
      'chroot' => false,
      'command' => 'error',
      'args' => [],
    },
  )

  use_alias_maps true

  use_virtual_aliases true
  virtual_aliases("@#{node['fqdn']}" => node['sanity']['root_email']) # send ALL emails for our FQDN to root_email

  sasl(relay['host'] => { 'username' => relay['username'], 'password' => relay['password'] }) if relay['username']
end

# the path unit also copies /etc/resolv.conf into the chroot whenever it changes
service 'postfix-resolvconf.path' do
  action %i(stop disable)
end

# remove the files copied into the chroot before syncing was disabled
%w(/var/spool/postfix/etc /var/spool/postfix/lib).each do |dir|
  directory dir do
    action :delete
    recursive true
  end
end
