# Sanity Cookbook

[![Funding](https://img.shields.io/liberapay/patrons/infertux.svg?logo=liberapay)](https://liberapay.com/infertux/donate)
[![Cookbook](https://img.shields.io/cookbook/v/sanity.svg)](https://supermarket.getchef.com/cookbooks/sanity)
[![Build Status](https://gitlab.com/infertux/chef-sanity/badges/master/pipeline.svg)](https://gitlab.com/infertux/chef-sanity/-/pipelines)

This cookbook helps you standardize configuration on various machines.
It applies a common set of packages and settings to any machine (VM, cloud, bare metal, etc.) so you have a solid base to build on.

Here are some highlights of what it does:

- sets up a basic firewall with nftables or iptables to block incoming connections (IPv4 and IPv6)
- sets up NTP and set timezone to UTC
- sets up a reliable DNS resolver
- sets up automatic package updates
- hardens sshd config with public key authentication and strong ciphers
- sets up a local MTA using Postfix to send emails to sysadmin
- sets up Monit to alert sysadmin when CPU, memory, disk, etc. is overused
- sets up SMART to monitor hard drive failures
- installs a few useful packages like tmux, htop, curl, etc.
- hardens various OS settings for better security

## Recipes

[`sanity::default`](https://github.com/infertux/chef-sanity/tree/master/recipes/default.rb) is a curated list of recipes that should fit most setups.

You can include [extra recipes](https://github.com/infertux/chef-sanity/tree/master/recipes) as you see fit.

## License

MIT
