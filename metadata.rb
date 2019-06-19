name             'sanity'
maintainer       'Cédric Félizard'
maintainer_email 'cedric@felizard.fr'
license          'MIT'
description      'An opinionated yet configurable set of packages and settings to make machines saner'
source_url       'https://github.com/infertux/chef-sanity'
issues_url       'https://github.com/infertux/chef-sanity/issues'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.0'
chef_version     '>= 14'

supports 'centos', '>= 7.0'
supports 'debian', '>= 9.5'

depends 'apt', '~> 7.1'
depends 'iptables-ng', '~> 4.0'
depends 'monit-ng', '~> 2.4'
depends 'openssh', '~> 2.7'
depends 'postfix', '~> 5.3'
depends 'resolver', '~> 2.1'
depends 'vim', '~> 2.0'
depends 'yum-epel', '~> 3.2'
