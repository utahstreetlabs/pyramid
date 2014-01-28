require 'pyramid/controllers/base'
require 'pyramid/models/like'
require 'pyramid/resources/count_query'
require 'sinatra/base'

module Pyramid
  class LikesController < Sinatra::Base
    include Controller

    get '/count' do
      respond { CountQuery.new(Like.count) }
    end
  end
end
