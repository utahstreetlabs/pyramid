require 'pyramid/resources/base'
require 'pyramid/models/likes_summary'

module Pyramid
  class LikeablesResource < ResourceBase
    class << self
      def likeables_likes_count_url(likeable_type, likeable_ids)
        lps = likeable_path_segment(likeable_type)
        qps = grouped_query_path_segment(likeable_ids)
        absolute_url("/#{lps}/many/#{qps}/likes/count")
      end

      def likeables_likes_recent_url(likeable_type, listing_ids = nil)
        if listing_ids.present?
          absolute_url("/#{likeable_path_segment(likeable_type)}/many/#{listing_ids.join(';')}/likes/recent")
        else
          absolute_url("/#{likeable_path_segment(likeable_type)}/likes/recent")
        end
      end

      def likeable_likes_count_url(likeable_id, likeable_type)
        absolute_url("/#{likeable_path_segment(likeable_type)}/#{likeable_id}/likes/count")
      end

      def likeable_likes_summary_url(likeable_id, likeable_type)
        absolute_url("/#{likeable_path_segment(likeable_type)}/#{likeable_id}/likes/summary")
      end

      def likeable_likes_visibility_url(likeable_id, likeable_type)
        absolute_url("/#{likeable_path_segment(likeable_type)}/#{likeable_id}/likes/visibility")
      end

      # @return [Pyramid::LikesSummary] ({count: 0, liker_ids: []})
      # @see Ladon::Resource::Base#fire_get
      def fire_likes_summary_query(url, options = {})
        options = options.reverse_merge(default_data: {count: 0, liker_ids: []})
        LikesSummary.new(fire_get(url, options))
      end
    end
  end
end
