require 'pyramid/controllers/base'
require 'pyramid/models/like'
require 'pyramid/resources/count_query'
require 'pyramid/resources/grouped_query'
require 'pyramid/resources/likes_summary'
require 'pyramid/resources/paged_query'
require 'sinatra/base'

module Pyramid
  class ListingsController < Sinatra::Base
    include Pyramid::Controller

    def respond_to_recent
      respond do
        days = params[:days].to_i
        params = truthified_params(:normalize, :counts)
        params[:exclude_liked_by_users] = params.delete(:xlbu)
        PagedQuery.new(Pyramid::Like.recent_for_likeable(:listing, days, params))
      end
    end

    get '/likes/recent' do
      respond_to_recent
    end

    get '/many/:listing_ids/likes/recent' do
      params[:ids] = grouped_query_ids(:listing_ids)
      respond_to_recent
    end

    get '/many/:listing_ids/likes/count' do
      respond do
        listing_ids = grouped_query_ids(:listing_ids)
        counts = Pyramid::Like.counts_for_likeables(:listing, listing_ids)
        GroupedQuery.new(listing_ids, counts, default: 0)
      end
    end

    get '/:listing_id/likes/count' do
      respond { CountQuery.new(Pyramid::Like.count_for_likeable(:listing, params[:listing_id])) }
    end

    get '/:listing_id/likes/summary' do
      respond do
        count = Pyramid::Like.count_for_likeable(:listing, params[:listing_id])
        # this approach of returning all liking user ids is so not scalable, but hopefully once we get follows into
        # pyramid we'll be able to return just the most popular likers
        liker_ids = Pyramid::Like.find_for_likeable(:listing, params[:listing_id], per: 100000, attr: [:user_id]).
          map(&:user_id)
        LikesSummary.new(count, liker_ids)
      end
    end

    put '/:listing_id/likes/visibility' do
      respond do
        Pyramid::Like.update_for_likeable(:listing, params[:listing_id], visible: true)
        [204, nil]
      end
    end

    delete '/:listing_id/likes/visibility' do
      respond do
        Pyramid::Like.update_for_likeable(:listing, params[:listing_id], visible: false)
      end
    end

    TRUTH_VALUES = Set.new([true, 'true', '1', 1])
    def truthified_params(*keys)
      # +HashWithIndifferentAccess+ causes some issues writing back to the hash if we use a symbol instead of a
      # string or vice versa, so we just iterate so we know what the keys are.  small enough hash to not stress.
      params.each_with_object(HashWithIndifferentAccess.new) do |(key,value),map|
        if keys.include?(key.to_sym)
          map[key] = TRUTH_VALUES.member?(value)
        else
          map[key] = value
        end
      end
    end
  end
end
