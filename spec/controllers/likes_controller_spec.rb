require 'spec_helper'
require 'rack/test'
require 'pyramid/controllers/likes_controller'

describe Pyramid::LikesController do
  include Rack::Test::Methods

  def app
    Pyramid::LikesController
  end

  context "GET /count" do
    it "returns the total number of likes" do
      Fabricate(:listing_like)
      Fabricate(:tag_like)
      get '/count'
      last_response.should be_count_query_result(2)
    end
  end
end
