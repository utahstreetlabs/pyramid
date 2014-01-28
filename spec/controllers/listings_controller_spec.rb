require 'spec_helper'
require 'rack/test'
require 'pyramid/controllers/listings_controller'

describe Pyramid::ListingsController do
  include Rack::Test::Methods

  def app
    Pyramid::ListingsController
  end

  let(:listing_id) { 12345 }
  let!(:l1) { Fabricate(:listing_like, listing_id: listing_id, created_at: 2.days.ago) }
  let!(:l2) { Fabricate(:listing_like, listing_id: listing_id) }
  let!(:l3) { Fabricate(:listing_like) }
  let!(:t1) { Fabricate(:tag_like) }
  let!(:t2) { Fabricate(:tag_like) }

  context "GET /likes/recent" do
    let(:days) { 2 }
    it "returns combined like ids within days sorted by like count" do
      l4 = Fabricate(:listing_like, listing_id: listing_id)
      get "likes/recent?days=1"
      last_response.json[:total].should == 2
      last_response.json[:collection].should == [{"listing_id" => l1.listing_id}, {"listing_id" => l3.listing_id}]
    end

    context 'parsing' do
      let(:fake_result) { Pyramid::Like.filter(id: l1.id).paginate }
      before do
        Pyramid::Like.expects(:recent_for_likeable).
          with(:listing, days, has_entries('counts' => parsed, 'normalize' => parsed)).returns(fake_result)
      end

      context 'with truthy values' do
        let(:parsed) { true }
        it 'parses correctly' do
          get "likes/recent?days=#{days}&counts=true&normalize=1"
        end
      end

      context 'with non-truthy values' do
        let(:parsed) { false }
        it 'parses correctly' do
          get "likes/recent?days=#{days}&counts=false&normalize="
        end
      end
    end
  end

  context 'GET /many/:listing_ids/likes/recent' do
    let!(:l4) { Fabricate(:listing_like, listing_id: listing_id) }
    let!(:l5) { Fabricate(:listing_like) }

    it 'returns listing ids ordered by number of likes in recent days and limited to requested ids' do
      get "/many/#{l3.listing_id};#{listing_id}/likes/recent"
      expect(last_response.json[:total]).to eq(2)
      expect(last_response.json[:collection]).to eq([{'listing_id' => listing_id}, {'listing_id' => l3.listing_id}])
    end
  end

  context "GET /many/:listing_ids/likes/count" do
    it "returns combined like counts grouped by listing id" do
      get "/many/#{l1.listing_id};#{l3.listing_id}/likes/count"
      last_response.should be_grouped_query_result({l1.listing_id => 2, l3.listing_id => 1})
    end
  end

  context "GET /:listing_id/likes/count" do
    it "returns the like count for a listing" do
      get "/#{listing_id}/likes/count"
      last_response.should be_count_query_result(2)
    end
  end

  context "GET /:listing_id/likes/summary" do
    it "returns the likes summary for a listing" do
      get "/#{listing_id}/likes/summary"
      last_response.json[:count].should == 2
      last_response.json[:liker_ids].should == [l2.user_id, l1.user_id]
    end
  end

  context 'PUT /:listing_id/likes/visibility' do
    it "makes the likes visible" do
      listing_id = 123
      likes = (1..3).map { Fabricate(:listing_like, listing_id: listing_id, visible: false) }
      likes.each do |like|
        like.should_not be_visible
      end
      put "/#{listing_id}/likes/visibility"
      last_response.status.should == 204
      likes.each do |like|
        like.reload
        like.should be_visible
      end
    end
  end

  context 'DELETE /:listing_id/likes/visibility' do
    it "makes the likes invisible" do
      listing_id = 123
      likes = (1..3).map { Fabricate(:listing_like, listing_id: listing_id, visible: true) }
      likes.each do |like|
        like.should be_visible
      end
      delete "/#{listing_id}/likes/visibility"
      last_response.status.should == 204
      likes.each do |like|
        like.reload
        like.should_not be_visible
      end
    end
  end
end
