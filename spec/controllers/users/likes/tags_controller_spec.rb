require 'spec_helper'
require 'rack/test'
require 'pyramid/controllers/users/likes/tags_controller'

describe Pyramid::Users::Likes::TagsController do
  include Rack::Test::Methods

  def app
    Pyramid::Users::Likes::TagsController
  end

  let(:user_id) { 1 }

  let!(:l1) { Fabricate(:listing_like, user_id: user_id, created_at: 2.days.ago) }
  let!(:l2) { Fabricate(:listing_like, user_id: user_id, created_at: 3.days.ago) }
  let!(:t1) { Fabricate(:tag_like, user_id: user_id, created_at: 1.day.ago) }
  let!(:t2) { Fabricate(:tag_like, user_id: user_id, created_at: 5.days.ago) }

  context 'GET /:user_id' do
    it "returns the likes in reverse chron order" do
      get "/#{user_id}", per: 1
      last_response.should be_paged_query_result(2, [t1])
    end
  end

  context 'GET /:user_id/count' do
    it "returns the like count" do
      get "/#{user_id}/count"
      last_response.should be_count_query_result(2)
    end
  end

  context 'GET /:user_id/many/:tag_ids/existences' do
    it "returns the like existences" do
      get "/#{user_id}/many/#{t1.tag_id};#{t2.tag_id};-30/existences"
      last_response.should be_grouped_query_result({t1.tag_id => true, t2.tag_id => true, -30 => false})
    end
  end

  context 'GET /:user_id/:tag_id' do
    it "returns the like" do
      get "/#{user_id}/#{t1.tag_id}"
      last_response.should be_entity_get_result(t1)
    end

    it "fails when the tag does not exist" do
      tag_id = Fabricate.sequence(:tag_id)
      get "/#{user_id}/#{tag_id}"
      last_response.status.should == 404
    end
  end

  context 'PUT /:user_id/:tag_id' do
    it "creates and returns a like" do
      old_count = Pyramid::Like.count
      tag_id = Fabricate.sequence(:tag_id)
      put "/#{user_id}/#{tag_id}"
      last_response.should be_entity_put_result(user_id: user_id, tag_id: tag_id)
      Pyramid::Like.count.should == old_count+1
    end

    it "undeletes and returns an existing deleted like" do
      t1.kill
      t1.reload
      t1.should be_deleted
      t1.tombstone.should be_true
      old_count = Pyramid::Like.count
      put "/#{user_id}/#{t1.tag_id}"
      last_response.should be_entity_put_result(user_id: user_id, tag_id: t1.tag_id)
      t1.reload
      t1.should_not be_deleted
      t1.tombstone.should be_true
      Pyramid::Like.count.should == old_count
    end

    it "returns conflict response for existing like" do
      old_count = Pyramid::Like.count
      put "/#{user_id}/#{t1.tag_id}"
      last_response.status.should == 409
      Pyramid::Like.count.should == old_count
    end
  end

  context 'DELETE /:user_id/:tag_id' do
    it "deletes a like and sets its tombstone" do
      t1.should_not be_deleted
      t1.tombstone.should be_false
      delete "/#{user_id}/#{t1.tag_id}"
      last_response.should be_entity_delete_result
      t1.reload
      t1.should be_deleted
      t1.tombstone.should be_true
    end

    it "preserves an existing deleted like's state" do
      t1.kill
      t1.reload
      t1.should be_deleted
      t1.tombstone.should be_true
      delete "/#{user_id}/#{t1.tag_id}"
      last_response.should be_entity_delete_result
      t1.reload
      t1.should be_deleted
      t1.tombstone.should be_true
    end

    it "silently fails to delete a nonexistent like" do
      tag_id = Fabricate.sequence(:tag_id)
      delete "/#{user_id}/#{tag_id}"
      last_response.should be_entity_delete_result
    end
  end
end
