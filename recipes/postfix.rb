node.default['postfix']['recipient_canonical_map_entries']['root'] = node['sanity']['root_email']

node.default['postfix']['mail_type'] = 'master' # or 'client'
node.default['postfix']['main']['compatibility_level'] = '2'
node.default['postfix']['main']['inet_interfaces'] = 'all'

# catch-all destination for unknown local(8) recipients
node.default['postfix']['main']['luser_relay'] = node['sanity']['root_email']

# TLS shared options
# https://security.stackexchange.com/questions/200176/is-tls-preempt-cipherlist-yes-in-postfix-a-good-idea-nowadays
node.default['postfix']['main']['tls_preempt_cipherlist'] = 'no'

# TLS client options
node.default['postfix']['main']['smtp_use_tls'] = 'yes'
node.default['postfix']['main']['smtp_tls_security_level'] = 'secure'
node.default['postfix']['main']['smtp_tls_note_starttls_offer'] = 'yes'

# TLS server options (smtpd_*)
# generated 2022-12-05, Mozilla Guideline v5.6, Postfix 3.5.13, OpenSSL 1.1.1n, modern configuration
# https://ssl-config.mozilla.org/#server=postfix&version=3.5.13&config=modern&openssl=1.1.1n&guideline=5.6
node.default['postfix']['main']['smtpd_tls_auth_only'] = 'yes'
node.default['postfix']['main']['smtpd_tls_security_level'] = 'may'
node.default['postfix']['main']['smtpd_tls_protocols'] = '!SSLv2, !SSLv3, !TLSv1, !TLSv1.1, !TLSv1.2'
node.default['postfix']['main']['smtpd_tls_mandatory_protocols'] = '!SSLv2, !SSLv3, !TLSv1, !TLSv1.1, !TLSv1.2'

# XXX: If smtpd is going to be used, proper certificates should be generated and
# set using the following attributes:
# node.default['postfix']['main']['smtpd_tls_cert_file'] = '/etc/ssl/certs/postfix.cert'
# node.default['postfix']['main']['smtpd_tls_key_file'] = '/etc/ssl/private/postfix.key'

# https://docs.aws.amazon.com/ses/latest/DeveloperGuide/postfix.html
# node.default['postfix']['main']['relayhost'] = '[email-smtp.us-west-2.amazonaws.com]:587'

if node['postfix']['sasl']
  node.default['postfix']['mail_type'] = 'client'
  node.default['postfix']['main']['smtp_sasl_auth_enable'] = 'yes'
  node.default['postfix']['main']['smtp_sasl_security_options'] = 'noanonymous'
  # node.default['postfix']['main']['smtp_sasl_password_maps'] = 'hash:/etc/postfix/sasl_passwd'
end

# add missing entry for retry service in master.cf
node.default['postfix']['master']['retry'] = {
  active: true,
  order: 900, # should be last, see https://github.com/sous-chefs/postfix/blob/main/attributes/default.rb
  type: 'unix',
  chroot: true,
  command: 'error',
  args: [],
}

include_recipe 'postfix::default'

include_recipe 'postfix::sasl_auth' if node['postfix']['sasl']

node.default['postfix']['aliases']['root'] = node['sanity']['root_email']

include_recipe 'postfix::aliases'
