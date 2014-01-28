module Pyramid
  class PagedQuery
    attr_reader :total, :collection

    def initialize(paged_array)
      @total = paged_array.pagination_record_count
      @collection = paged_array.map(&:values)
    end

    def to_json
      {total: total, collection: collection}.to_json
    end
  end
end
