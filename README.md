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
- sets up a local Mail Transfer Agent using Postfix to send emails to sysadmin
- sets up Monit to alert sysadmin when CPU, memory, disk, etc. is overused
- sets up SMART to monitor hard drive failures
- installs a few useful packages like tmux, btop, curl, etc.
- hardens various OS settings for better security

## Recipes

[`sanity::default`](https://github.com/infertux/chef-sanity/tree/master/recipes/default.rb) is a curated list of recipes that should fit most setups.

You can include [extra recipes](https://github.com/infertux/chef-sanity/tree/master/recipes) as you see fit.

### Customizing Postfix

[`sanity::postfix`](https://github.com/infertux/chef-sanity/tree/master/recipes/postfix.rb) configures Postfix with the `postfix 'default'` resource from the [postfix cookbook](https://github.com/sous-chefs/postfix).
To customize it, edit that resource from a wrapper recipe after including sanity, e.g. to send emails through a relayhost with SASL authentication:

```ruby
include_recipe 'sanity'

edit_resource!(:postfix, 'default') do
  main_settings(
    main_settings.merge(
      'relayhost' => '[email-smtp.us-west-2.amazonaws.com]:587',
      'smtp_sasl_auth_enable' => 'yes', # also configures SASL using the credentials below
    ),
  )
  sasl('[email-smtp.us-west-2.amazonaws.com]:587' => { 'username' => 'AKIA...', 'password' => 'secret' })
end
```

## License

MIT
