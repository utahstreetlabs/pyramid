require 'spec_helper'
require 'rack/test'
require 'pyramid/controllers/tags_controller'

describe Pyramid::TagsController do
  include Rack::Test::Methods

  def app
    Pyramid::TagsController
  end

  let(:tag_id) { 12345 }
  let!(:l1) { Fabricate(:tag_like) }
  let!(:l2) { Fabricate(:tag_like) }
  let!(:t1) { Fabricate(:tag_like, tag_id: tag_id, created_at: 2.days.ago) }
  let!(:t2) { Fabricate(:tag_like, tag_id: tag_id) }
  let!(:t3) { Fabricate(:tag_like) }

  context "GET /many/:tag_ids/likes/count" do
    it "returns combined like counts grouped by tag id" do
      get "/many/#{t1.tag_id};#{t3.tag_id}/likes/count"
      last_response.should be_grouped_query_result({t1.tag_id => 2, t3.tag_id => 1})
    end
  end

  context "GET /:tag_id/likes/count" do
    it "returns the like count for a tag" do
      get "/#{tag_id}/likes/count"
      last_response.should be_count_query_result(2)
    end
  end

  context "GET /:tag_id/likes/summary" do
    it "returns the likes summary for a tag" do
      get "/#{tag_id}/likes/summary"
      last_response.json[:count].should == 2
      last_response.json[:liker_ids].should == [t2.user_id, t1.user_id]
    end
  end

  context 'PUT /:tag_id/likes/visibility' do
    it "makes the likes visible" do
      tag_id = 123
      likes = (1..3).map { Fabricate(:tag_like, tag_id: tag_id, visible: false) }
      likes.each do |like|
        like.should_not be_visible
      end
      put "/#{tag_id}/likes/visibility"
      last_response.status.should == 204
      likes.each do |like|
        like.reload
        like.should be_visible
      end
    end
  end

  context 'DELETE /:tag_id/likes/visibility' do
    it "makes the likes invisible" do
      tag_id = 123
      likes = (1..3).map { Fabricate(:tag_like, tag_id: tag_id, visible: true) }
      likes.each do |like|
        like.should be_visible
      end
      delete "/#{tag_id}/likes/visibility"
      last_response.status.should == 204
      likes.each do |like|
        like.reload
        like.should_not be_visible
      end
    end
  end
end
