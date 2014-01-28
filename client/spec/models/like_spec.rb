require 'spec_helper'
require 'pyramid/models/like'

describe Pyramid::Like do
  describe '#count' do
    it 'returns the total count of likes' do
      count = 10000
      Pyramid::LikesResource.expects(:fire_count_query).
        with(Pyramid::LikesResource.likes_count_url).
        returns(count)
      Pyramid::Like.count.should == count
    end
  end
end
