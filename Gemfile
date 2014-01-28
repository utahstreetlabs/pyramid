source :rubygems

gem 'activesupport'
gem 'log_weasel'
gem 'mysql2'
gem 'sequel'
gem 'sinatra'
gem 'unicorn'

group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'fabrication'
  gem 'mocha'
  gem 'rack-test'
  gem 'database_cleaner'
  gem 'foreman'
end

group :development do
  gem 'awesome_print'
  gem 'bson_ext' # XXX: can be removed once likes are migrated from lagunitas
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'hipchat'
  gem 'mongo' # XXX: can be removed once likes are migrated from lagunitas
  gem 'progress_bar' # XXX: can be removed once likes are migrated from lagunitas
  gem 'racksh'
  gem 'thor'
  if ENV['PYRAMID_DEBUG']
    gem 'ruby-debug19'
    gem 'ruby-debug-base19'
  end
end
