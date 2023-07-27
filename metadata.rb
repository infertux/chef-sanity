name             'sanity'
maintainer       'Cédric Félizard'
maintainer_email 'cedric@felizard.fr'
license          'MIT'
description      'An opinionated yet configurable set of packages and settings to make machines saner'
source_url       'https://github.com/infertux/chef-sanity'
issues_url       'https://github.com/infertux/chef-sanity/issues'

version          '3.3.0'
chef_version     '>= 18'

supports 'debian', '>= 10.0'
supports 'ubuntu', '>= 22.04'

depends 'apt', '~> 7.5'
depends 'iptables-ng', '~> 4.1'
depends 'monit-ng', '~> 2.4'
depends 'os-hardening', '~> 4.0'
depends 'postfix', '~> 6.0'
depends 'resolver', '~> 4.1'
depends 'ssh-hardening', '~> 2.9'
