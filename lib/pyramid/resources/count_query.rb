module Pyramid
  class CountQuery
    attr_reader :count

    def initialize(count)
      @count = count
    end

    def to_json
      {count: count}.to_json
    end
  end
end
