require 'ladon/model'

module Pyramid
  class LikesSummary < Ladon::Model
    attr_accessor :count, :liker_ids
  end
end
