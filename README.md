# Sanity Cookbook

[![Funding](https://img.shields.io/liberapay/patrons/infertux.svg?logo=liberapay)](https://liberapay.com/infertux/donate)
[![Cookbook](https://img.shields.io/cookbook/v/sanity.svg)](https://supermarket.getchef.com/cookbooks/sanity)
[![Build Status](https://github.com/infertux/chef-sanity/actions/workflows/test.yml/badge.svg)](https://github.com/infertux/chef-sanity/actions)

***chef-sanity brings back your sanity as a sysadmin.***

This cookbook helps you standardize configuration on various machines.
It applies a common set of packages and settings to any machine (VM, cloud, bare metal, etc.) so you have a solid base to build on.

Here are some highlights of what it does:

- sets up a basic firewall with nftables to block incoming connections (IPv4 and IPv6)
- sets up NTP and set timezone to UTC
- sets up a reliable DNS resolver
- sets up automatic package updates
- hardens sshd config with public key authentication and strong ciphers
- sets up a local Mail Transfer Agent using Postfix to send emails to sysadmin, directly or through a relay
- sets up Monit to alert sysadmin when CPU, memory, disk, etc. is overused
- sets up SMART to monitor hard drive failures
- installs a few useful packages like tmux, btop, curl, etc.
- hardens various OS settings for better security

## Recipes

[`sanity::default`](https://github.com/infertux/chef-sanity/tree/master/recipes/default.rb) is a curated list of recipes that should fit most setups.

You can include [extra recipes](https://github.com/infertux/chef-sanity/tree/master/recipes) as you see fit.

### Sending emails through a relay

By default, Postfix delivers emails directly to the recipients' mail servers, so they come from each machine's FQDN.
To send them through a relay instead, e.g. a mail provider's SMTP submission server, set these attributes:

```ruby
node.default['sanity']['root_email'] = 'alerts@example.net' # where emails for root, Monit alerts, etc. go
node.default['sanity']['postfix']['relay'] = {
  'host' => '[smtp.example.net]:587',
  'username' => 'alerts@example.net', # omit username and password if the relay doesn't require authentication
  'password' => 'secret',
}
```

With a relay, the envelope and header sender of every email is rewritten to `root_email`,
since relays usually only accept their own address as sender (e.g. Proton Mail's SMTP tokens, Amazon SES verified identities).
It also means only one domain sends emails on behalf of all your machines, which keeps SPF and DMARC simple.
To use another sender, override `sender_canonical_maps` as shown below.

### Customizing Postfix

[`sanity::postfix`](https://github.com/infertux/chef-sanity/tree/master/recipes/postfix.rb) configures Postfix with the `postfix 'default'` resource from the [postfix cookbook](https://github.com/sous-chefs/postfix).
To customize it further, edit that resource from a wrapper recipe after including sanity, e.g. to change a `main.cf` setting:

```ruby
include_recipe 'sanity'

edit_resource!(:postfix, 'default') do
  main_settings(main_settings.merge('message_size_limit' => '52428800'))
end
```

## License

MIT
