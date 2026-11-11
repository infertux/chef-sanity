name             'sanity'
maintainer       'Cédric Félizard'
maintainer_email 'cedric@felizard.fr'
license          'MIT'
description      'Standardize configuration of various machines (VM, cloud, bare metal, etc.) with a common set of packages and settings'
source_url       'https://github.com/infertux/chef-sanity'
issues_url       'https://github.com/infertux/chef-sanity/issues'

version          '4.4.0'
chef_version     '>= 18'

supports 'debian', '>= 13.0'

depends 'apt', '~> 7.7'
depends 'os-hardening', '~> 4.2'
depends 'postfix', '~> 7.0'
depends 'resolver', '~> 4.2'
depends 'ssh-hardening', '~> 2.9'
