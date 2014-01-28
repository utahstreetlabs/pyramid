$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

# load general dependencies
require 'rubygems'
require 'bundler'

# Bundler >= 1.0.10 uses Psych YAML, which is broken, so fix that.
# https://github.com/carlhuda/bundler/issues/1038
require 'yaml'
YAML::ENGINE.yamler = 'syck'

Bundler.require

# load initializers
Dir.glob(File.join('.', 'config', 'initializers', '*.rb')).each {|file| require file}

# load stuff used in this file
require 'sinatra/base'
require 'pyramid/controllers/likes_controller'
require 'pyramid/controllers/listings_controller'
require 'pyramid/controllers/root_controller'
require 'pyramid/controllers/tags_controller'
require 'pyramid/controllers/users_controller'

# rack setup
use LogWeasel::Middleware
map('/') { run Pyramid::RootController }
map('/likes') { run Pyramid::LikesController }
map('/users') { run Pyramid::UsersController }
map('/listings') { run Pyramid::ListingsController }
map('/tags') { run Pyramid::TagsController }
