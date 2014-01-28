require 'pyramid/resources/base'

module Pyramid
  class UsersResource < ResourceBase
    class << self
      def user_url(id)
        absolute_url("/users/#{id}")
      end

      def users_likes_count_url(ids)
        absolute_url("/users/many/#{grouped_query_path_segment(ids)}/likes/count")
      end

      def user_likes_url(id)
        absolute_url("/users/#{id}/likes")
      end

      def user_likes_count_url(id)
        absolute_url("/users/#{id}/likes/count")
      end

      def user_likeable_likes_url(likeable_type, id)
        absolute_url("/users/#{id}/likes/#{likeable_path_segment(likeable_type)}")
      end

      def user_likeable_likes_count_url(likeable_type, id)
        absolute_url("/users/#{id}/likes/#{likeable_path_segment(likeable_type)}/count")
      end

      def users_likeable_likes_count_url(likeable_type, ids)
        absolute_url("/users/#{grouped_query_path_segment(ids)}/likes/#{likeable_path_segment(likeable_type)}count")
      end

      def user_likeables_likes_existences_url(likeable_type, id, likeable_ids)
        lps = likeable_path_segment(likeable_type)
        gqps = grouped_query_path_segment(likeable_ids)
        absolute_url("/users/#{id}/likes/#{lps}/many/#{gqps}/existences")
      end

      def user_likeable_like_url(likeable_type, id, likeable_id)
        absolute_url("/users/#{id}/likes/#{likeable_path_segment(likeable_type)}/#{likeable_id}")
      end

      def user_likeable_like_visibility_url(likeable_type, id, likeable_id)
        absolute_url("/users/#{id}/likes/#{likeable_path_segment(likeable_type)}/#{likeable_id}/visibility")
      end

      def user_hot_or_not_suggestions_url(id)
        absolute_url("/users/#{id}/hot-or-not-suggestions")
      end
    end
  end
end
