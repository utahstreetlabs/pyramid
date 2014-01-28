require 'pyramid/controllers/base'
require 'pyramid/models/like'
require 'pyramid/version'
require 'sinatra/base'

module Pyramid
  class RootController < Sinatra::Base
    include Controller

    set :version_string, "Pyramid v#{Pyramid::VERSION}"

    configure do
      logger.info "Starting #{settings.version_string}"
    end

    get '/' do
      respond(representation: :txt) { settings.version_string }
    end

    delete '/' do
      respond { Like.delete }
    end
  end
end
