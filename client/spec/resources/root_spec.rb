require 'spec_helper'
require 'pyramid/resources/root_resource'

describe Pyramid::RootResource do
  context "#nuke" do
    it "clears everything" do
      Pyramid::RootResource.expects(:fire_delete).with('/').once
      Pyramid::RootResource.nuke
    end
  end
end
