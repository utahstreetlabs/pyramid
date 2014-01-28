module Pyramid
  class LikesSummary
    attr_reader :count, :liker_ids

    def initialize(count, liker_ids)
      @count = count
      @liker_ids = liker_ids
    end

    def to_json
      {count: count, liker_ids: liker_ids}.to_json
    end
  end
end
