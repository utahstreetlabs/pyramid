require 'pyramid/resources/likeables_resource'

module Pyramid
  class Likeable
    class Likes
      class << self
        # @return [Hash] (id => 0 for each id)
        # @see Pyramid::ResourceBase#fire_grouped_count_query
        def count_many(likeable_type, likeable_ids, options = {})
          url = LikeablesResource.likeables_likes_count_url(likeable_type, likeable_ids)
          LikeablesResource.fire_grouped_count_query(url, likeable_ids, options)
        end

        def recent(likeable_type, days, options = {})
          # creating a /many/id;id;id;/... url can get too long and cause an HTTP 414, so we batch requests
          # and reassemble in the client
          if options[:listing_ids].present? && options[:batch_size]
            batch_size = options.delete(:batch_size)
            with_counts = options[:listing_ids].each_slice(batch_size).flat_map do |ids|
              results = recent(likeable_type, days, options.merge(counts: true, listing_ids: ids, per: batch_size))
              results.map { |l| [l['listing_id'], l['count']] }
            end
            with_counts.sort_by { |r| [-r.last, -r.first] }.map(&:first)
          else
            url = LikeablesResource.likeables_likes_recent_url(likeable_type, options[:listing_ids])
            LikeablesResource.fire_recent_count_query(url, days, options)
          end
        end

        def count(likeable_id, likeable_type, options = {})
          url = LikeablesResource.likeable_likes_count_url(likeable_id, likeable_type)
          LikeablesResource.fire_count_query(url, options)
        end

        def summary(likeable_id, likeable_type, options = {})
          url = LikeablesResource.likeable_likes_summary_url(likeable_id, likeable_type)
          LikeablesResource.fire_likes_summary_query(url, options)
        end

        # Makes the likeable's likes visible if not already so.
        #
        # @see Ladon::Resource::Base#fire_put
        def reveal(likeable_id, likeable_type, options = {})
          url = LikeablesResource.likeable_likes_visibility_url(likeable_id, likeable_type)
          LikeablesResource.fire_put(url, options)
        end

        # Makes the likeable's likes invisible if not already so.
        #
        # @see Ladon::Resource::Base#fire_delete
        def hide(likeable_id, likeable_type, options = {})
          url = LikeablesResource.likeable_likes_visibility_url(likeable_id, likeable_type)
          LikeablesResource.fire_delete(url, options)
        end
      end
    end
  end
end
