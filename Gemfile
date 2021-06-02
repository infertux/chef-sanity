source 'https://rubygems.org'

gem 'berkshelf', groups: %i(development test)

group :development do
  gem 'chef', '~> 14'
  gem 'rake'
end

group :style do
  gem 'cookstyle'
end

group :test do
  gem 'kitchen-inspec'
  gem 'kitchen-dokken'
  gem 'test-kitchen', '~> 2.1.0'
end
