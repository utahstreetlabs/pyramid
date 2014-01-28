$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
ENV['RACK_ENV'] = 'test'

# load general dependencies
require 'rubygems'
require 'bundler'
Bundler.setup :default, :test

# load stuff used in this file
require 'active_support/core_ext'
require 'database_cleaner'
require 'rspec'
require 'fabrication'
require 'pyramid/database'
require 'pyramid/logging'

# set up logging
Dir.mkdir('log') unless File.exists?('log')
Pyramid.logger = Logger.new(File.join('log', 'test.log'))

# set up database
Pyramid::Database.connect!

# load spec support files
Dir[File.join('.', 'spec', 'support', '**', '*.rb')].each {|file| require file}

# configure rspec
RSpec.configure do |config|
  config.mock_with :mocha

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
