source 'https://rubygems.org'

gem 'rake', group: :development
gem 'berkshelf', groups: %i(development test) # needed by test-kitchen

group :style do
  gem 'cookstyle'
end

group :test do
  gem 'chef-bin',         source: 'https://packagecloud.io/cinc-project/stable'
  gem 'cinc-auditor-bin', source: 'https://packagecloud.io/cinc-project/stable' # inspec fork from cinc-project
  gem 'kitchen-dokken'
  gem 'kitchen-inspec'
  gem 'kitchen-vagrant'
  gem 'test-kitchen'

  # XXX: use patched mixlib-install Gem from cinc-project otherwise license-acceptance doesn't know about "product_name: cinc" in .kitchen.yml
  # https://gitlab.com/cinc-project/upstream/mixlib-install/-/blob/stable/cinc/lib/mixlib/install/product_matrix.rb
  gem 'mixlib-install', source: 'https://packagecloud.io/cinc-project/stable'
end
