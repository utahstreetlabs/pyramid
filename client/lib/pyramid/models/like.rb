require 'ladon/model'
require 'pyramid/resources/likes_resource'

module Pyramid
  class Like < Ladon::Model
    attr_accessor :user_id, :listing_id, :tag_id, :tombstone

    class << self
      def count
        LikesResource.fire_count_query(LikesResource.likes_count_url)
      end
    end
  end
end
