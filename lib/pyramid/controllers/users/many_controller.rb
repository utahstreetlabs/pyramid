require 'pyramid/controllers/base'
require 'pyramid/models/like'
require 'pyramid/resources/grouped_query'
require 'sinatra/base'

module Pyramid
  module Users
    class ManyController < Sinatra::Base
      include Pyramid::Controller

      get '/:user_ids/likes/count' do
        respond do
          user_ids = grouped_query_ids(:user_ids)
          counts = Pyramid::Like.counts_for_users(user_ids)
          GroupedQuery.new(user_ids, counts, default: 0)
        end
      end

      get '/:user_ids/likes/listings/count' do
        respond do
          user_ids = grouped_query_ids(:user_ids)
          counts = Pyramid::Like.counts_for_users(user_ids, type: :listing)
          GroupedQuery.new(user_ids, counts, default: 0)
        end
      end

      get '/:user_ids/likes/tags/count' do
        respond do
          user_ids = grouped_query_ids(:user_ids)
          counts = Pyramid::Like.counts_for_users(user_ids, type: :tag)
          GroupedQuery.new(user_ids, counts, default: 0)
        end
      end
    end
  end
end
