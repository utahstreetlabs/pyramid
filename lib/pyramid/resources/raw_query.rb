module Pyramid
  class RawQuery
    attr_reader :results

    def initialize(array)
      @results = array
    end

    def to_json
      results.to_json
    end
  end
end
