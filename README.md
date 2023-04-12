# Sanity Cookbook

[![Funding](https://img.shields.io/liberapay/patrons/infertux.svg?logo=liberapay)](https://liberapay.com/infertux/donate)
[![Sponsors](https://img.shields.io/liberapay/patrons/infertux)](https://liberapay.com/infertux)
[![Cookbook](https://img.shields.io/cookbook/v/sanity.svg)](https://supermarket.getchef.com/cookbooks/sanity)
[![Build Status](https://gitlab.com/infertux/chef-sanity/badges/master/pipeline.svg)](https://gitlab.com/infertux/chef-sanity/-/pipelines)

This cookbook is an opinionated but configurable set of packages and settings to make machines saner.

Here are some highlights of what it does:

- sets timezone to UTC and enables NTP
- sets up a basic firewall with nftables or iptables to block incoming connections (IPv4 and IPv6)
- hardens sshd config with public key authentication and strong ciphers
- sets up a local MTA using Postfix to send emails to sysadmin
- sets up Monit to alert sysadmin when CPU, memory, disk, etc. is overused
- sets up unattended_upgrades (Debian only)
- sets up a reliable DNS resolver
- installs a few useful packages like tmux, htop, curl, etc.

## Recipes

[`sanity::default`](https://github.com/infertux/chef-sanity/tree/master/recipes/default.rb) is a curated list of recipes that should fit most setups.

You can include [extra recipes](https://github.com/infertux/chef-sanity/tree/master/recipes) as you see fit.

## License

MIT
