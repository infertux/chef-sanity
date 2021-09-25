source 'https://rubygems.org'

gem 'rake', group: :development
gem 'berkshelf', groups: %i(development test) # needed by test-kitchen

group :style do
  gem 'cookstyle'
end

group :test do
  gem 'test-kitchen'
  #gem 'chef-bin', '~> 17', source: 'https://packagecloud.io/cinc-project/stable'
  gem 'cinc-auditor-bin', source: 'https://packagecloud.io/cinc-project/stable' # inspec fork from cinc-project
  gem 'kitchen-dokken'
  gem 'kitchen-inspec'
  #gem 'kitchen-sync' # speed up file transfers using sftp or rsync
  gem 'kitchen-vagrant'

  # XXX: use patched mixlib-install Gem from cinc-project otherwise license-acceptance doesn't know about "product_name: cinc" in .kitchen.yml
  # https://gitlab.com/cinc-project/upstream/mixlib-install/-/blob/stable/cinc/lib/mixlib/install/product_matrix.rb
  gem 'mixlib-install', source: 'https://packagecloud.io/cinc-project/stable'
  # gem 'mixlib-install', git: 'https://gitlab.com/cinc-project/mixlib-install.git', branch: 'stable/cinc'
end
