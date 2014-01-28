require 'pyramid/controllers/base'
require 'pyramid/controllers/users/likes/tags/visibility_controller'
require 'pyramid/models/like'
require 'pyramid/resources/count_query'
require 'pyramid/resources/grouped_query'
require 'pyramid/resources/paged_query'
require 'sinatra/base'

module Pyramid
  module Users
    module Likes
      class TagsController < Sinatra::Base
        include Pyramid::Controller

        get '/:user_id' do
          respond do
            options = paged_query_params.merge(type: :tag)
            PagedQuery.new(Pyramid::Like.find_for_user(params[:user_id], options))
          end
        end

        get '/:user_id/count' do
          respond { CountQuery.new(Pyramid::Like.count_for_user(params[:user_id], type: :tag)) }
        end

        get '/:user_id/many/:tag_ids/existences' do
          respond do
            tag_ids = grouped_query_ids(:tag_ids)
            existences = Pyramid::Like.existences_for_user(params[:user_id], :tag, tag_ids)
            GroupedQuery.new(tag_ids, existences, default: false)
          end
        end

        get '/:user_id/:tag_id' do
          respond { Pyramid::Like.get_for_user(params[:user_id], :tag, params[:tag_id], entity_get_params) }
        end

        put '/:user_id/:tag_id' do
          respond do
            begin
              Pyramid::Like.create(user_id: params[:user_id], tag_id: params[:tag_id])
            rescue Pyramid::Like::DuplicateLike
              tag = Pyramid::Like.get_for_user(params[:user_id], :tag, params[:tag_id], ignore_deleted: true)
              if tag.deleted?
                tag.update(deleted: false)
                tag
              else
                [409, nil]
              end
            end
          end
        end

        delete '/:user_id/:tag_id' do
          respond do
            like = Pyramid::Like.get_for_user(params[:user_id], :tag, params[:tag_id], attrs: [:id])
            like.kill if like
          end
        end

        get '/:user_id/:tag_id/visibility' do
          delegate_to_subcontroller Pyramid::Users::Likes::Tags::VisibilityController,
            prefix: "/#{params[:user_id]}/#{params[:tag_id]}"
        end

        put '/:user_id/:tag_id/visibility' do
          delegate_to_subcontroller Pyramid::Users::Likes::Tags::VisibilityController,
            prefix: "/#{params[:user_id]}/#{params[:tag_id]}"
        end
      end
    end
  end
end
