require 'spec_helper'
require 'pyramid/models/user'

describe Pyramid::User do
  let(:user_id) { 54321 }

  describe '::destroy' do
    it 'deletes a user' do
      Pyramid::UsersResource.expects(:fire_delete).with(Pyramid::UsersResource.user_url(user_id))
      Pyramid::User.destroy(user_id)
    end
  end

  describe '::hot_or_not_suggestions' do
    it 'gets hot or not suggestions' do
      Pyramid::UsersResource.expects(:fire_get).with(Pyramid::UsersResource.user_hot_or_not_suggestions_url(user_id))
      Pyramid::User.hot_or_not_suggestions(user_id)
    end
  end
end
