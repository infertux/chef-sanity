name             'sanity'
maintainer       'Cédric Félizard'
maintainer_email 'cedric@felizard.fr'
license          'MIT'
description      'An opinionated yet configurable set of packages and settings to make machines saner'
source_url       'https://github.com/infertux/chef-sanity'
issues_url       'https://github.com/infertux/chef-sanity/issues'

version          '3.0.0'
chef_version     '>= 14.6'

supports 'debian', '>= 9.9'

depends 'apt', '~> 7.4'
depends 'iptables-ng', '~> 4.0'
depends 'monit-ng', '~> 2.4'
depends 'openssh', '~> 2.9'
depends 'postfix', '~> 6.0'
depends 'resolver', '~> 3.0'
depends 'vim', '~> 2.1'

# Indirect dependency restrictions for Chef version < 15:
depends 'iptables', '< 8'
depends 'seven_zip', '< 4'
