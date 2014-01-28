require 'pyramid/controllers/base'
require 'pyramid/controllers/users/likes/listings/visibility_controller'
require 'pyramid/models/like'
require 'pyramid/resources/count_query'
require 'pyramid/resources/grouped_query'
require 'pyramid/resources/paged_query'
require 'sinatra/base'

module Pyramid
  module Users
    module Likes
      class ListingsController < Sinatra::Base
        include Pyramid::Controller

        get '/:user_id' do
          respond do
            options = paged_query_params.merge(type: :listing)
            PagedQuery.new(Pyramid::Like.find_for_user(params[:user_id], options))
          end
        end

        get '/:user_id/count' do
          respond { CountQuery.new(Pyramid::Like.count_for_user(params[:user_id], type: :listing)) }
        end

        get '/:user_id/many/:listing_ids/existences' do
          respond do
            listing_ids = grouped_query_ids(:listing_ids)
            existences = Pyramid::Like.existences_for_user(params[:user_id], :listing, listing_ids)
            GroupedQuery.new(listing_ids, existences, default: false)
          end
        end

        get '/:user_id/:listing_id' do
          respond { Pyramid::Like.get_for_user(params[:user_id], :listing, params[:listing_id], entity_get_params) }
        end

        put '/:user_id/:listing_id' do
          respond do
            begin
              Pyramid::Like.create(user_id: params[:user_id], listing_id: params[:listing_id])
            rescue Pyramid::Like::DuplicateLike
              listing = Pyramid::Like.get_for_user(params[:user_id], :listing, params[:listing_id],
                ignore_deleted: true)
              if listing.deleted?
                listing.update(deleted: false)
                listing
              else
                [409, nil]
              end
            end
          end
        end

        delete '/:user_id/:listing_id' do
          respond do
            like = Pyramid::Like.get_for_user(params[:user_id], :listing, params[:listing_id], attrs: [:id])
            like.kill if like
          end
        end

        get '/:user_id/:listing_id/visibility' do
          delegate_to_subcontroller Pyramid::Users::Likes::Listings::VisibilityController,
            prefix: "/#{params[:user_id]}/#{params[:listing_id]}"
        end

        put '/:user_id/:listing_id/visibility' do
          delegate_to_subcontroller Pyramid::Users::Likes::Listings::VisibilityController,
            prefix: "/#{params[:user_id]}/#{params[:listing_id]}"
        end
      end
    end
  end
end
