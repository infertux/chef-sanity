settings = {
  # https://www.postfix.org/COMPATIBILITY_README.html
  'compatibility_level' => '3.6',
  'inet_interfaces' => 'all',
  'inet_protocols' => node['sanity']['postfix']['inet_protocols'] || (node['sanity']['ipv6'] ? 'all' : 'ipv4'),

  # TLS shared options
  # https://security.stackexchange.com/questions/200176/is-tls-preempt-cipherlist-yes-in-postfix-a-good-idea-nowadays
  'tls_preempt_cipherlist' => 'no',

  # smtp(d)_use_tls are deprecated in favor of smtp(d)_tls_security_level: nil removes the cookbook's defaults from main.cf,
  # so we have to set the settings the cookbook derives from them ourselves
  'smtp_use_tls' => nil,
  'smtpd_use_tls' => nil,

  # TLS client options
  'smtp_tls_security_level' => 'verify',
  'smtp_tls_note_starttls_offer' => 'yes',
  'smtp_tls_CAfile' => '/etc/ssl/certs/ca-certificates.crt',
  'smtp_tls_session_cache_database' => 'btree:${data_directory}/smtp_scache',

  # TLS server options (smtpd_*)
  # generated 2022-12-05, Mozilla Guideline v5.6, Postfix 3.5.13, OpenSSL 1.1.1n, modern configuration
  # https://ssl-config.mozilla.org/#server=postfix&version=3.5.13&config=modern&openssl=1.1.1n&guideline=5.6
  'smtpd_tls_auth_only' => 'yes',
  'smtpd_tls_security_level' => 'may',
  'smtpd_tls_protocols' => '!SSLv2, !SSLv3, !TLSv1, !TLSv1.1, !TLSv1.2',
  'smtpd_tls_mandatory_protocols' => '!SSLv2, !SSLv3, !TLSv1, !TLSv1.1, !TLSv1.2',
  'smtpd_tls_session_cache_database' => 'btree:${data_directory}/smtpd_scache',
  # XXX: If smtpd is going to be used, proper certificates should be generated and
  # set with smtpd_tls_cert_file and smtpd_tls_key_file (see README)
  'smtpd_tls_cert_file' => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  'smtpd_tls_key_file' => '/etc/ssl/private/ssl-cert-snakeoil.key',
}

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
