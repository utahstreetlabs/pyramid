require 'spec_helper'
require 'rack/test'
require 'pyramid/controllers/users/many_controller'

describe Pyramid::Users::ManyController do
  include Rack::Test::Methods

  def app
    Pyramid::Users::ManyController
  end

  let!(:l1) { Fabricate(:listing_like, user_id: 1) }
  let!(:t1) { Fabricate(:tag_like, user_id: 1) }
  let!(:t2) { Fabricate(:tag_like, user_id: 2) }

  context "GET /:user_ids/likes/count" do
    it "returns combined like counts grouped by user id" do
      get '/1;2/likes/count'
      last_response.should be_grouped_query_result({1 => 2, 2 => 1})
    end
  end

  context "GET /:user_ids/likes/listings/count" do
    it "returns listing like counts grouped by user id" do
      get '/1;2/likes/listings/count'
      last_response.should be_grouped_query_result({1 => 1, 2 => 0})
    end
  end

  context "GET /:user_ids/likes/tags/count" do
    it "returns tag like counts grouped by user id" do
      get '/1;2/likes/tags/count'
      last_response.should be_grouped_query_result({1 => 1, 2 => 1})
    end
  end
end
