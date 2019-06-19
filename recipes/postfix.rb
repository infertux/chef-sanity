node.default['postfix']['recipient_canonical_map_entries']['root'] = node['sanity']['root_email']

node.default['postfix']['mail_type'] = 'master' # or 'client'
node.default['postfix']['main']['inet_interfaces'] = 'all'

# TLS shared options
node.default['postfix']['main']['tls_preempt_cipherlist'] = 'yes'
node.default['postfix']['main']['tls_medium_cipherlist'] = 'AES128+EECDH:AES128+EDH'

# TLS client options
node.default['postfix']['main']['smtp_use_tls'] = 'yes'
node.default['postfix']['main']['smtp_tls_security_level'] = 'encrypt'
node.default['postfix']['main']['smtp_tls_note_starttls_offer'] = 'yes'

# TLS server options (smtpd_*)
node.default['postfix']['main']['smtpd_tls_auth_only'] = 'yes'
node.default['postfix']['main']['smtpd_tls_security_level'] = 'may'
node.default['postfix']['main']['smtpd_tls_protocols'] = '!SSLv2,!SSLv3,!TLSv1,!TLSv1.1'
node.default['postfix']['main']['smtpd_tls_mandatory_protocols'] = '!SSLv2,!SSLv3,!TLSv1,!TLSv1.1'

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

include_recipe 'postfix::default'

include_recipe 'postfix::sasl_auth' if node['postfix']['sasl']

node.default['postfix']['aliases']['root'] = node['sanity']['root_email']

include_recipe 'postfix::aliases'
