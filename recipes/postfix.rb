package 'msmtp-mta' do
  action :purge # FIXME: remove
end

node.default['postfix']['aliases']['root'] ||= node['sanity']['aliases']['root']
node.default['postfix']['main']['inet_interfaces'] = 'all'
node.default['postfix']['mail_type'] = 'master' # or 'client'

# https://docs.aws.amazon.com/ses/latest/DeveloperGuide/postfix.html
node.default['postfix']['main']['relayhost'] = '[email-smtp.us-west-2.amazonaws.com]:587'

node.default['postfix']['main']['smtp_use_tls'] = 'yes'
node.default['postfix']['main']['smtp_tls_security_level'] = 'encrypt'
node.default['postfix']['main']['smtp_tls_note_starttls_offer'] = 'yes'

node.default['postfix']['main']['smtp_sasl_auth_enable'] = 'yes'
node.default['postfix']['main']['smtp_sasl_security_options'] = 'noanonymous'
node.default['postfix']['main']['smtp_sasl_password_maps'] = 'hash:/etc/postfix/sasl_passwd'

node.default['postfix']['sasl'] = {
  "relayhost1" => {
    "username" => "your_password",
    "password" => "your_username"
  }
}

include_recipe 'postfix::default'
include_recipe 'postfix::sasl_auth'

node.default['zeyple']['gpg']['keys'] = [node['sanity']['aliases']['root']]

include_recipe 'zeyple::default'
