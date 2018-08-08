name             'sanity'
maintainer       'Cédric Félizard'
maintainer_email 'cedric@felizard.fr'
license          'MIT'
description      'An opinionated yet configurable set of packages and settings to make machines saner'
source_url       'https://github.com/infertux/chef-sanity'
issues_url       'https://github.com/infertux/chef-sanity/issues'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.3.0'
chef_version     '>= 14'

supports 'debian', '>= 9.4'

depends 'cronapt', '~> 0.3'
depends 'fluentbit', '~> 1.1'
depends 'htop', '~> 2.0'
depends 'iptables-ng', '~> 3.0'
depends 'monit-ng', '~> 2.4'
depends 'msmtp', '~> 1.1'
depends 'openssh', '~> 2.6'
depends 'postfix', '~> 5.3'
depends 'resolver', '~> 2.1'
depends 'tmux', '~> 1.5'
depends 'vim', '~> 2.0'
depends 'zeyple', '~> 1.2'
