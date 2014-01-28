require 'rubygems'
require 'bundler'

Bundler.setup

require 'mocha'
require 'rspec'
require 'ladon'
require 'pyramid/resources/base'

Ladon.hydra = Typhoeus::Hydra.new
Ladon.logger = Logger.new('/dev/null')

Pyramid::ResourceBase.base_url = 'http://localhost:4051'

RSpec.configure do |config|
  config.mock_with :mocha
end
