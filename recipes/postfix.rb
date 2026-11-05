settings = {
  'compatibility_level' => '2',
  'inet_interfaces' => 'all',

  # TLS shared options
  # https://security.stackexchange.com/questions/200176/is-tls-preempt-cipherlist-yes-in-postfix-a-good-idea-nowadays
  'tls_preempt_cipherlist' => 'no',

  # TLS client options
  'smtp_use_tls' => 'yes',
  'smtp_tls_security_level' => 'verify',
  'smtp_tls_note_starttls_offer' => 'yes',

  # TLS server options (smtpd_*)
  # generated 2022-12-05, Mozilla Guideline v5.6, Postfix 3.5.13, OpenSSL 1.1.1n, modern configuration
  # https://ssl-config.mozilla.org/#server=postfix&version=3.5.13&config=modern&openssl=1.1.1n&guideline=5.6
  'smtpd_tls_auth_only' => 'yes',
  'smtpd_tls_security_level' => 'may',
  'smtpd_tls_protocols' => '!SSLv2, !SSLv3, !TLSv1, !TLSv1.1, !TLSv1.2',
  'smtpd_tls_mandatory_protocols' => '!SSLv2, !SSLv3, !TLSv1, !TLSv1.1, !TLSv1.2',
  # XXX: If smtpd is going to be used, proper certificates should be generated and
  # set with smtpd_tls_cert_file and smtpd_tls_key_file (see README)
}

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
