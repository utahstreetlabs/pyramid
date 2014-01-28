require 'pyramid/resources/base'

module Pyramid
  class LikesResource < ResourceBase
    class << self
      def likes_count_url(params = {})
        absolute_url("/likes/count", params)
      end
    end
  end
end
