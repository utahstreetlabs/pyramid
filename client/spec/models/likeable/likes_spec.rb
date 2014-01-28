require 'spec_helper'
require 'pyramid/models/likeable/likes'

describe Pyramid::Likeable::Likes do
  let(:likeable_id) { 12345 }
  let(:likeable_type) { :fnord }

  describe '#count_many' do
    it 'calls Pyramid::LikeablesResource#fire_grouped_count_query and returns counts' do
      grouped = stub
      likeable_ids = [123, 456, 789]
      url = Pyramid::LikeablesResource.likeables_likes_count_url(likeable_type, likeable_ids)
      Pyramid::LikeablesResource.expects(:fire_grouped_count_query).
        with(url, likeable_ids, is_a(Hash)).
        returns(grouped)
      Pyramid::Likeable::Likes.count_many(likeable_type, likeable_ids).should == grouped
    end
  end

  describe '#recent' do
    let(:grouped) { stub('grouped') }
    let(:days) { 2 }

    context 'without listing ids' do
      let(:url) { Pyramid::LikeablesResource.likeables_likes_recent_url(likeable_type) }
      it 'calls Pyramid::LikeablesResource#fire_grouped_count_query and returns recent counts' do
        Pyramid::LikeablesResource.expects(:fire_recent_count_query).
          with(url, days, is_a(Hash)).
          returns(grouped)
        expect(Pyramid::Likeable::Likes.recent(likeable_type, days)).to eq(grouped)
      end
    end

    context 'with listing ids' do
      let(:batch_size) { 5 }
      let(:listing_ids) { (1..2*batch_size).to_a }
      let(:options) { {listing_ids: listing_ids, batch_size: batch_size} }
      let(:responses) do
        listing_ids.each_slice(batch_size).map { |s| s.map { |id| {'listing_id' => id, 'count' => id} } }
      end
      let(:urls) do
        listing_ids.each_slice(batch_size).map do |slice|
          Pyramid::LikeablesResource.likeables_likes_recent_url(likeable_type, slice)
        end
      end

      it 'calls Pyramid::LikeablesResource#fire_grouped_count_query and returns recent counts' do
        listing_ids.each_slice(batch_size).each_with_index do |slice, i|
          Pyramid::LikeablesResource.expects(:fire_recent_count_query).
            with(urls[i], days, has_entry(per: batch_size)).
            returns(responses[i])
        end
        expect(Pyramid::Likeable::Likes.recent(likeable_type, days, options)).to eq(listing_ids.reverse)
      end
    end
  end

  describe '#count' do
    it 'returns the total count of listing likes' do
      count = 10000
      Pyramid::LikeablesResource.expects(:fire_count_query).
        with(Pyramid::LikeablesResource.likeable_likes_count_url(likeable_id, likeable_type), is_a(Hash)).
        returns(count)
      Pyramid::Likeable::Likes.count(likeable_id, likeable_type).should == count
    end
  end

  describe '#summary' do
    it 'returns the summary listing likes' do
      data = stub
      Pyramid::LikeablesResource.expects(:fire_likes_summary_query).
        with(Pyramid::LikeablesResource.likeable_likes_summary_url(likeable_id, likeable_type), is_a(Hash)).
        returns(data)
      Pyramid::Likeable::Likes.summary(likeable_id, likeable_type).should == data
    end
  end
end
