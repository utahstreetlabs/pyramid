require 'spec_helper'
require 'rack/test'
require 'pyramid/controllers/root_controller'
require 'pyramid/models/like'

describe Pyramid::RootController do
  include Rack::Test::Methods

  def app
    Pyramid::RootController
  end

  context 'GET /' do
    it "shows name and version" do
      get '/'
      last_response.status.should == 200
      last_response.body.should == "Pyramid v#{Pyramid::VERSION}"
    end
  end

  context 'DELETE /' do
    it 'deletes all likes' do
      Fabricate(:listing_like)
      Fabricate(:tag_like)
      delete '/'
      last_response.status.should == 204
      last_response.body.should be_empty
      Pyramid::Like.count.should == 0
    end
  end
end
