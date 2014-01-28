require 'spec_helper'
require 'rack/test'
require 'pyramid/controllers/users/likes/tags/visibility_controller'

describe Pyramid::Users::Likes::Tags::VisibilityController do
  include Rack::Test::Methods

  def app
    Pyramid::Users::Likes::Tags::VisibilityController
  end

  context 'PUT /:user_id/:tag_id' do
    it "makes the like visible" do
      like = Fabricate(:tag_like, visible: false)
      like.should_not be_visible
      put "/#{like.user_id}/#{like.tag_id}"
      last_response.status.should == 204
      like.reload
      like.should be_visible
    end

    it "returns 404 when the like does not exist" do
      put "/345/678"
      last_response.status.should == 404
    end
  end

  context 'DELETE /:user_id/:tag_id' do
    it "makes the like invisible" do
      like = Fabricate(:tag_like, visible: true)
      like.should be_visible
      delete "/#{like.user_id}/#{like.tag_id}"
      last_response.status.should == 204
      like.reload
      like.should_not be_visible
    end

    it "returns 404 when the like does not exist" do
      delete "/345/678"
      last_response.status.should == 404
    end
  end
end
