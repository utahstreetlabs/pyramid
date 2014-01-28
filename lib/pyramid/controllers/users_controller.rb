require 'pyramid/controllers/base'
require 'pyramid/controllers/users/many_controller'
require 'pyramid/controllers/users/likes/listings_controller'
require 'pyramid/controllers/users/likes/tags_controller'
require 'pyramid/models/like'
require 'pyramid/resources/paged_query'
require 'pyramid/resources/raw_query'
require 'sinatra/base'

module Pyramid
  class UsersController < Sinatra::Base
    include Pyramid::Controller

    delete '/:id' do
      respond { Pyramid::Like.delete_all_for_user(params[:id].to_i) }
    end

    get '/many/*' do
      delegate_to_subcontroller Pyramid::Users::ManyController
    end

    get '/:id/likes' do
      respond { PagedQuery.new(Pyramid::Like.find_for_user(params[:id], paged_query_params)) }
    end

    get '/:id/likes/count' do
      respond { CountQuery.new(Pyramid::Like.count_for_user(params[:id])) }
    end

    get '/:id/hot-or-not-suggestions' do
      limit = (params[:limit] || 100).to_i
      respond { RawQuery.new(Pyramid::Like.hot_or_not_suggestions_for_user(params[:id], limit: limit)) }
    end

    # XXX: Sinatra extension to generate all subcontroller routes

    get '/:id/likes/listings' do
      delegate_to_subcontroller Pyramid::Users::Likes::ListingsController, prefix: "/#{params[:id]}"
    end

    get '/:id/likes/listings/*' do
      delegate_to_subcontroller Pyramid::Users::Likes::ListingsController, prefix: "/#{params[:id]}"
    end

    put '/:id/likes/listings/*' do
      delegate_to_subcontroller Pyramid::Users::Likes::ListingsController, prefix: "/#{params[:id]}"
    end

    delete '/:id/likes/listings/*' do
      delegate_to_subcontroller Pyramid::Users::Likes::ListingsController, prefix: "/#{params[:id]}"
    end

    # XXX: Sinatra extension to generate all subcontroller routes

    get '/:id/likes/tags' do
      delegate_to_subcontroller Pyramid::Users::Likes::TagsController, prefix: "/#{params[:id]}"
    end

    get '/:id/likes/tags/*' do
      delegate_to_subcontroller Pyramid::Users::Likes::TagsController, prefix: "/#{params[:id]}"
    end

    put '/:id/likes/tags/*' do
      delegate_to_subcontroller Pyramid::Users::Likes::TagsController, prefix: "/#{params[:id]}"
    end

    delete '/:id/likes/tags/*' do
      delegate_to_subcontroller Pyramid::Users::Likes::TagsController, prefix: "/#{params[:id]}"
    end
  end
end
