require 'spec_helper'
require 'rack/test'
require 'pyramid/controllers/users/likes/listings_controller'

describe Pyramid::Users::Likes::ListingsController do
  include Rack::Test::Methods

  def app
    Pyramid::Users::Likes::ListingsController
  end

  let(:user_id) { 1 }

  let!(:l1) { Fabricate(:listing_like, user_id: user_id, created_at: 2.days.ago) }
  let!(:l2) { Fabricate(:listing_like, user_id: user_id, created_at: 3.days.ago) }
  let!(:t1) { Fabricate(:tag_like, user_id: user_id, created_at: 1.day.ago) }
  let!(:t2) { Fabricate(:tag_like, user_id: user_id, created_at: 5.days.ago) }

  context 'GET /:user_id' do
    it "returns the likes in reverse chron order" do
      get "/#{user_id}", per: 1
      last_response.should be_paged_query_result(2, [l1])
    end
  end

  context 'GET /:user_id/count' do
    it "returns the like count" do
      get "/#{user_id}/count"
      last_response.should be_count_query_result(2)
    end
  end

  context 'GET /:user_id/many/:listing_ids/existences' do
    it "returns the like existences" do
      get "/#{user_id}/many/#{l1.listing_id};#{l2.listing_id};-30/existences"
      last_response.should be_grouped_query_result({l1.listing_id => true, l2.listing_id => true, -30 => false})
    end
  end

  context 'GET /:user_id/:listing_id' do
    it "returns the like" do
      get "/#{user_id}/#{l1.listing_id}"
      last_response.should be_entity_get_result(l1)
    end

    it "fails when the listing does not exist" do
      listing_id = Fabricate.sequence(:listing_id)
      get "/#{user_id}/#{listing_id}"
      last_response.status.should == 404
    end
  end

  context 'PUT /:user_id/:listing_id' do
    it "creates and returns a like" do
      old_count = Pyramid::Like.count
      listing_id = Fabricate.sequence(:listing_id)
      put "/#{user_id}/#{listing_id}"
      last_response.should be_entity_put_result(user_id: user_id, listing_id: listing_id)
      Pyramid::Like.count.should == old_count+1
    end

    it "undeletes and returns an existing deleted like" do
      l1.kill
      l1.reload
      l1.should be_deleted
      l1.tombstone.should be_true
      old_count = Pyramid::Like.count
      put "/#{user_id}/#{l1.listing_id}"
      last_response.should be_entity_put_result(user_id: user_id, listing_id: l1.listing_id)
      l1.reload
      l1.should_not be_deleted
      l1.tombstone.should be_true
      Pyramid::Like.count.should == old_count
    end

    it "returns conflict response for existing like" do
      old_count = Pyramid::Like.count
      put "/#{user_id}/#{l1.listing_id}"
      last_response.status.should == 409
      Pyramid::Like.count.should == old_count
    end
  end

  context 'DELETE /:user_id/:listing_id' do
    it "deletes a like and sets its tombstone" do
      l1.should_not be_deleted
      l1.tombstone.should be_false
      delete "/#{user_id}/#{l1.listing_id}"
      last_response.should be_entity_delete_result
      l1.reload
      l1.should be_deleted
      l1.tombstone.should be_true
    end

    it "preserves an existing deleted like's state" do
      l1.kill
      l1.reload
      l1.should be_deleted
      l1.tombstone.should be_true
      delete "/#{user_id}/#{l1.listing_id}"
      last_response.should be_entity_delete_result
      l1.reload
      l1.should be_deleted
      l1.tombstone.should be_true
    end

    it "silently fails to delete a nonexistent like" do
      listing_id = Fabricate.sequence(:listing_id)
      delete "/#{user_id}/#{listing_id}"
      last_response.should be_entity_delete_result
    end
  end
end
