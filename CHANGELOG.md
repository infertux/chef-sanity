## Unreleased ([changes](https://github.com/infertux/chef-sanity/compare/3.3.0...master))

  * TBD

## v3.3.0, 2023-07-27 ([changes](https://github.com/infertux/chef-sanity/compare/3.2.1...3.3.0))

  * f65bd46 - Harden sshd config and disable RSA host key
  * ce11ca3 - Set up GitHub workflow to run Test Kitchen
  * 67e4ff1 - Update dependencies
  * 35cae39 - Fix Rubocop violations
  * 551d602 - Add support for nftables

## v3.2.1, 2023-06-22 ([changes](https://github.com/infertux/chef-sanity/compare/3.2.0...3.2.1))

  * bac6693 - Fix coredump detection

## v3.2.0, 2023-05-26 ([changes](https://github.com/infertux/chef-sanity/compare/3.1.1...3.2.0))

 * 8dd8eb4 - Drop support for Chef 17 and Debian 10
 * 45a48e0 - Update dependencies
 * 5f14ba9 - Log coredumps with systemd and fail run if any are found

## v3.1.1, 2023-05-06 ([changes](https://github.com/infertux/chef-sanity/compare/3.1.0...3.1.1))

  * 85b1a6f - Bump SMART warnings to max temperature to avoid false alerts
  * 29dcb7d - Update dependencies

## v3.1.0, 2023-04-22 ([changes](https://github.com/infertux/chef-sanity/compare/3.0.0...3.1.0))

  * 94372d7 - Test against multiple Chef versions
  * 401fe68 - Add missing Gems for GitLab CI
  * efeaf00 - Update documentation for release 3.1.0
  * 4549de8 - Move connectivity checks to an InSpec Profile
  * bac767d - Don't install Chef/Cinc tools via Gemfile

## v3.0.0, 2023-04-12 ([changes](https://github.com/infertux/chef-sanity/compare/2.2.0...3.0.0))

  * 35a16e3 - Add preliminary support for Ubuntu LTS
  * 3d299c5 - Fix GitLab CI integration
  * 69d3573 - Update dependencies
  * 3507b17 - Fix Kitchen CI test suite
  * fcf3c4e - Don't remove nfs-common and rpcbind as they are useful in some cases
  * 00eb0af - Update dependencies
  * e6134f6 - Update dependencies
  * d08a99a - Add missing entry for Postfix retry service
  * e5ec977 - Modernize Postfix SSL/TLS config
  * a4cde65 - Fix UTC timezone for Debian 11
  * 09e9d12 - Increase SMART temperature warnings to avoid false positive spam
  * 91e6c6b - Update dependencies
  * 5c970d9 - Increase SMART temperature warnings to avoid false positive spam
  * 2e48b66 - Fix systemctl path for Debian 11
  * a6e1cb0 - Enable automatic SMART checks
  * a4c3988 - Update dependencies
  * 2db3496 - Use `systemctl reboot` instead of `reboot`
  * 260b286 - Listen on IPv4 as well when IPv6 is enabled
  * 48cebf6 - Use a more reliable method to check for DNSSEC
  * b66877c - Refactor cookbook for new major version 3

  BREAKING CHANGES:
  - dropped support for Debian 9
  - replaced EULA Chef with Free Software CINC
  - renamed node['sanity']['firewall'] to node['sanity']['firewall']['type']
  - renamed node['sanity']['iptables']['ssh_authorized_ips_v4'] to node['sanity']['firewall']['ssh_authorized_ips_v4']
  - renamed node['sanity']['iptables']['ssh_authorized_ips_v6'] to node['sanity']['firewall']['ssh_authorized_ips_v6']

## v2.2.0, 2022-03-07 ([changes](https://github.com/infertux/chef-sanity/compare/2.1.0...2.2.0))

  * cc6b956 Fix the build for new ruby Docker image
  * f62fe38 Extract DNS servers as attributes
  * 7ce7c73 Switch from Vagrant to kitchen-dokken
  * 102b594 Use systemd resolved for DNS
  * ba5784e Drop support for discontinued CentOS
  * a92a0d7 Set up network interfaces automatically
  * a1ea577 Don't log unhandled UDP traffic
  * 62c6685 Update dependencies
  * 8b6f949 Use new Chef resource to set timezone to UTC
  * e9d43b6 Update dependencies
  * a6be455 Make sure ntp package is uninstalled
  * a9f0248 Use ShellOut to comply with http://www.foodcritic.io/#FC048
  * da74ae0 Update Gems
  * ba11518 Check free space on all regular filesystems
  * 17dfb8a Forward all unknown local recipients to root
  * 925f21f Update CHANGELOG

## v2.1.0, 2020-06-23 ([changes](https://github.com/infertux/chef-sanity/compare/2.0.1...2.1.0))

  * ffd9a59 Allow to whitelist non-free packages
  * a7be684 Bump rack from 2.2.2 to 2.2.3
  * 5370c31 Update dependencies
  * 0ff3153 Bump activesupport from 5.2.4.1 to 5.2.4.3
  * 50f5892 Keep old config upon updating package with conflict
  * 26b20d9 Make sure the ping program is installed
  * aa5eb33 Don't run Postfix in backwards-compatible mode
  * 2588893 Set smtpd_relay_restrictions for newer Postfix versions
  * 857feb1 Bump nokogiri from 1.10.7 to 1.10.8
  * f1a0f0e Fix broken NTP detection on Debian 10
  * 643c390 Update dependencies
  * 36272f5 Rename auto_reboot to automatic_reboot
  * e91f8b7 Don't recreate the backports repo on every Chef run
  * 2669d5e Use platform helper to make Cookstyle happy
  * 69e8b40 Bump version to 2.1.0
  * ff6ec90 Use numeric ports for NetBIOS
  * d073819 Enable backports on Debian Buster to get Monit package
  * 4bc1912 Update dependencies
  * e2053d6 Test against Debian 10
  * 5d78c58 Don't log UDP broadcast spam
  * 9d1b48e Update dependencies
  * 6fe120a Make sure apt-transport-https package is installed
  * 3612e01 Update dependencies

## v2.0.1, 2019-08-23 ([changes](https://github.com/infertux/chef-sanity/compare/2.0.0...2.0.1))

  * [BUGFIX] Don't email about successful package upgrades
  * [BUGFIX] Update Gems
  * [BUGFIX] Use built-in `apt_update` resource

## v2.0.0, 2019-06-19 ([changes](https://github.com/infertux/chef-sanity/compare/1.3.0...2.0.0))

  * First stable release. Enjoy!

## v1.0.0 to v1.3.0, 2018-02-17 to 2019-06-19 ([changes](https://github.com/infertux/chef-sanity/compare/1.0.0...1.3.0))

  * Experimental pre-releases. You should avoid to use these versions.
