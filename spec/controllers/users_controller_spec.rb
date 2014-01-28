require 'spec_helper'
require 'rack/test'
require 'pyramid/controllers/users_controller'

describe Pyramid::UsersController do
  include Rack::Test::Methods

  def app
    Pyramid::UsersController
  end

  let!(:l1) { Fabricate(:listing_like, user_id: 1, created_at: 2.days.ago) }
  let!(:t1) { Fabricate(:tag_like, user_id: 1) }
  let!(:t2) { Fabricate(:tag_like, user_id: 2) }

  context "GET /:id/likes" do
    it "returns likes for a user" do
      get '/1/likes', page: 1, per: 1
      last_response.should be_paged_query_result(2, [t1])
    end
  end

  context "GET /:id/likes/count" do
    it "returns like count for a user" do
      get '/1/likes/count'
      last_response.should be_count_query_result(2)
    end
  end

  context "GET /:id/hot-or-not-suggestions" do
    let!(:me) { 1 }
    let!(:someone_else) { 2 }
    let!(:third_person) { 3 }
    let!(:something_i_have_liked) { 1 }
    let!(:something_someone_else_has_liked) { 2 }
    let!(:something_else_someone_else_has_liked) { 3 }
    let!(:something_we_have_both_liked) { 4 }
    let!(:l1) { Fabricate(:listing_like, user_id: me, listing_id: something_i_have_liked) }
    let!(:l2) { Fabricate(:listing_like, user_id: someone_else, listing_id: something_someone_else_has_liked) }
    let!(:l3) { Fabricate(:listing_like, user_id: someone_else, listing_id: something_else_someone_else_has_liked) }
    let!(:l4) { Fabricate(:listing_like, user_id: me, listing_id: something_we_have_both_liked) }
    let!(:l5) { Fabricate(:listing_like, user_id: someone_else, listing_id: something_we_have_both_liked) }
    let!(:l6) { Fabricate(:listing_like, user_id: third_person, listing_id: something_someone_else_has_liked) }
    let!(:l7) { Fabricate(:listing_like, user_id: third_person, listing_id: something_we_have_both_liked) }

    it "returns hot or not suggestions for a user" do
      get '/1/hot-or-not-suggestions'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("[2,3]")
      get '/1/hot-or-not-suggestions?limit=1'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("[2]")
    end
  end

  context 'DELETE /:id' do
    it 'successfully deletes user data' do
      # we're relying on some preconditions, so blow up if those change
      expect(Pyramid::Like.where(user_id: 1).count).to eq(2)
      delete '/1'
      expect(last_response.status).to eq(204)
      expect(Pyramid::Like.where(user_id: 1).count).to eq(0)
    end
  end
end
