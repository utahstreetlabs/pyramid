require 'pyramid/controllers/base'
require 'pyramid/models/like'
require 'pyramid/resources/count_query'
require 'pyramid/resources/likes_summary'
require 'sinatra/base'

module Pyramid
  class TagsController < Sinatra::Base
    include Pyramid::Controller

    get '/many/:tag_ids/likes/count' do
      respond do
        tag_ids = grouped_query_ids(:tag_ids)
        counts = Pyramid::Like.counts_for_likeables(:tag, tag_ids)
        GroupedQuery.new(tag_ids, counts, default: 0)
      end
    end

    get '/:tag_id/likes/count' do
      respond { CountQuery.new(Pyramid::Like.count_for_likeable(:tag, params[:tag_id])) }
    end

    get '/:tag_id/likes/summary' do
      respond do
        count = Pyramid::Like.count_for_likeable(:tag, params[:tag_id])
        # this approach of returning all liking user ids is so not scalable, but hopefully once we get follows into
        # pyramid we'll be able to return just the most popular likers
        liker_ids = Pyramid::Like.find_for_likeable(:tag, params[:tag_id], per: 100000, attr: [:user_id]).
          map(&:user_id)
        LikesSummary.new(count, liker_ids)
      end
    end

    put '/:tag_id/likes/visibility' do
      respond do
        Pyramid::Like.update_for_likeable(:tag, params[:tag_id], visible: true)
        [204, nil]
      end
    end

    delete '/:tag_id/likes/visibility' do
      respond do
        Pyramid::Like.update_for_likeable(:tag, params[:tag_id], visible: false)
      end
    end
  end
end
