require 'pyramid/controllers/base'
require 'pyramid/models/like'
require 'sinatra/base'

module Pyramid
  module Users
    module Likes
      module Listings
        class VisibilityController < Sinatra::Base
          include Pyramid::Controller

          put '/:user_id/:listing_id' do
            respond do
              like.update(visible: true)
              [204, nil]
            end
          end

          delete '/:user_id/:listing_id' do
            respond { like.update(visible: false) }
          end

          helpers do
            def like
              unless @like
                @like = Pyramid::Like.get_for_user(params[:user_id], :listing, params[:listing_id],
                  attrs: [:id, :visible], ignore_visibility: true)
                halt('Like not found', status: 404) unless @like
              end
              @like
            end
          end
        end
      end
    end
  end
end
