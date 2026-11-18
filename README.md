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
- sets up sysstat to record CPU, memory, disk and network activity every minute, to look back at it with `sar`
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

### Custom firewall rules

[`sanity::firewall`](https://github.com/infertux/chef-sanity/tree/master/recipes/firewall.rb) blocks all incoming connections except SSH.
To open more ports, declare `sanity_nft` resources with full `nft` commands, e.g. in the `input-custom` chain:

```ruby
sanity_nft 'add rule inet filter input-custom tcp dport { 80, 443 } counter accept'
```

- `priority` (default `100`): rules are written in ascending priority order, then in declaration order, so a chain can be created before the rules that use it.
- `firewall_name` (default `'default'`): the `sanity_firewall` to add the rule to.
  Each `sanity_firewall` (alias `firewall`) writes its rules to its `path`, `/etc/nftables.d/custom.nft` for the default one.

Rules are only applied once the Chef run succeeds: each file is then checked with `nft --check` along with the rest of the ruleset, written, and nftables is reloaded once.
If the run fails or `nft` rejects a rule, the current rules are kept.
Removing the last `sanity_nft` empties the file.

## Attributes

All attributes live under `node['sanity']`, see [`attributes/default.rb`](https://github.com/infertux/chef-sanity/tree/master/attributes/default.rb) for their defaults.

| Attribute | Default | Description |
| --- | --- | --- |
| `automatic_reboot` | `'monthly'` | Reboot at a random time `'monthly'` or `'weekly'`; `false` to disable |
| `email2telegram` | `{}` | Set `token` and `chat_id` to forward outgoing emails to Telegram |
| `firewall.ssh_authorized_ips_v4` | `nil` | IPv4 sources allowed to SSH; `nil` means any |
| `firewall.ssh_authorized_ips_v6` | `nil` | IPv6 sources allowed to SSH; `nil` means none |
| `ipv4_reachable` | auto-detected | Whether the primary IPv4 is public; if so, sshd only listens on it |
| `ipv6` | `true` | `false` disables IPv6, and makes SSH and Postfix use IPv4 only |
| `monit` | see defaults | Alert thresholds (`cpu`, `loadavg`, `memory`, `swap`, `uptime`, `filesystem`, etc.) |
| `network.interfaces.manage` | `true` | Switch the network configuration to systemd-networkd (DHCP and IPv6 autoconfiguration) |
| `ntp` | `'systemd-timesyncd'` | `'ntp'` to use ntpsec instead |
| `packages.install` | `btop`, `curl`, `vim`, etc. | Packages to install |
| `packages.purge` | `['bind9']` | Packages to purge |
| `packages.fail_on_leftover_configuration_files` | `false` | Fail the run if `*.dpkg-*` or `*.ucf-*` files are left in `/etc` |
| `postfix.inet_protocols` | `nil` | `'all'`, or `'ipv4'` if IPv6 is disabled; set to `'ipv4'` to keep IPv6 but not for Postfix |
| `postfix.relay` | `{}` | See [Sending emails through a relay](#sending-emails-through-a-relay) |
| `repositories.backports` | `false` | Add backports (pinned, so only installed on request) |
| `repositories.testing` | `false` | Add testing, pinned to 100 (`apt install -t testing foo`) |
| `repositories.firmware` | `nil` | Add the non-free-firmware component; `nil` means only on bare metal |
| `repositories.protocol` | `'https'` | `'http'` or `'https'` |
| `resolver.dns` | Cloudflare and OpenDNS | DNS servers, IPv6 ones are left out if IPv6 is disabled |
| `resolver.dnssec` | `true` | Validate DNSSEC |
| `root_email` | `''` | Where emails for root go; they stay in root's local mailbox if empty |
| `smartmontools.enable` | `true` | `false` for machines without HDD/SSD storage |
| `ssh.authorized_keys` | `nil` | Keys written to root's `authorized_keys`; left untouched if empty |
| `swap.swappiness` | `10` | `vm.swappiness` |
| `swap.swapfile.path` | `'/swapfile'` | Path of the swap file |
| `swap.swapfile.size` | `0` | Swap file size in GiB; `0` to disable |
| `sysstat.enable` | `true` | `false` purges sysstat and its history |
| `sysstat.interval` | `1` | Minutes between recordings, must divide 60 |

## License

MIT
