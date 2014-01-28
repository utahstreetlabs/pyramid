require 'spec_helper'
require 'pyramid/models/user/likes'

describe Pyramid::User::Likes do
  let(:id) { 12345 }
  let(:likeable_type) { :tag }

  describe '#find' do
    it 'calls Pyramid::UsersResource#fire_paged_query and returns combined likes' do
      paged_array = stub
      Pyramid::UsersResource.expects(:fire_paged_query).
        with(Pyramid::UsersResource.user_likes_url(id), is_a(Hash)).
        returns(paged_array)
      Pyramid::User::Likes.find(id).should == paged_array
    end

    it 'calls Pyramid::UsersResource#fire_paged_query and returns typed likes' do
      paged_array = stub
      Pyramid::UsersResource.expects(:fire_paged_query).
        with(Pyramid::UsersResource.user_likeable_likes_url(likeable_type, id), is_a(Hash)).
        returns(paged_array)
      Pyramid::User::Likes.find(id, type: likeable_type).should == paged_array
    end
  end

  describe '#count' do
    it 'calls Pyramid::UsersResource#fire_count_query and returns combined count' do
      count = 10000
      Pyramid::UsersResource.expects(:fire_count_query).
        with(Pyramid::UsersResource.user_likes_count_url(id), is_a(Hash)).
        returns(count)
      Pyramid::User::Likes.count(id).should == count
    end

    it 'calls Pyramid::UsersResource#fire_count_query and returns typed count' do
      count = 10000
      Pyramid::UsersResource.expects(:fire_count_query).
        with(Pyramid::UsersResource.user_likeable_likes_count_url(likeable_type, id), is_a(Hash)).
        returns(count)
      Pyramid::User::Likes.count(id, type: likeable_type).should == count
    end
  end

  describe '#count_many' do
    it 'calls Pyramid::UsersResource#fire_count_query and returns combined counts' do
      grouped = stub
      ids = [123, 456, 789]
      Pyramid::UsersResource.expects(:fire_grouped_count_query).
        with(Pyramid::UsersResource.users_likes_count_url(ids), ids, is_a(Hash)).
        returns(grouped)
      Pyramid::User::Likes.count_many(ids).should == grouped
    end

    it 'calls Pyramid::UsersResource#fire_count_query and returns typed counts' do
      grouped = stub
      ids = [123, 456, 789]
      Pyramid::UsersResource.expects(:fire_grouped_count_query).
        with(Pyramid::UsersResource.users_likeable_likes_count_url(likeable_type, ids), ids, is_a(Hash)).
        returns(grouped)
      Pyramid::User::Likes.count_many(ids, type: likeable_type).should == grouped
    end
  end

  describe '#existences' do
    it 'calls Pyramid::UsersResource#fire_grouped_existence_query' do
      grouped = stub
      listing_ids = [123, 456, 789]
      url = Pyramid::UsersResource.user_likeables_likes_existences_url(likeable_type, id, listing_ids)
      Pyramid::UsersResource.expects(:fire_grouped_existence_query).
        with(url, listing_ids, is_a(Hash)).
        returns(grouped)
      Pyramid::User::Likes.existences(id, likeable_type, listing_ids).should == grouped
    end
  end

  describe '#get' do
    it 'calls Pyramid::UsersResource#fire_entity_get' do
      like = stub
      listing_id = 123
      Pyramid::UsersResource.expects(:fire_entity_get).
        with(Pyramid::UsersResource.user_likeable_like_url(likeable_type, id, listing_id), Pyramid::Like, is_a(Hash)).
        returns(like)
      Pyramid::User::Likes.get(id, likeable_type, listing_id).should == like
    end
  end

  describe '#create' do
    it 'calls Pyramid::UsersResource#fire_entity_put' do
      like = stub
      listing_id = 123
      Pyramid::UsersResource.expects(:fire_entity_put).
        with(Pyramid::UsersResource.user_likeable_like_url(likeable_type, id, listing_id), Pyramid::Like, is_a(Hash)).
        returns(like)
      Pyramid::User::Likes.create(id, likeable_type, listing_id).should == like
    end
  end

  describe '#destroy' do
    it 'calls Pyramid::UsersResource#fire_delete' do
      listing_id = 123
      Pyramid::UsersResource.expects(:fire_delete).
        with(Pyramid::UsersResource.user_likeable_like_url(likeable_type, id, listing_id), is_a(Hash))
      Pyramid::User::Likes.destroy(id, likeable_type, listing_id)
    end
  end

  describe '#reveal' do
    it 'calls Pyramid::UsersResource#fire_entity_put' do
      listing_id = 123
      url = Pyramid::UsersResource.user_likeable_like_visibility_url(likeable_type, id, listing_id)
      Pyramid::UsersResource.expects(:fire_put).with(url,is_a(Hash))
      Pyramid::User::Likes.reveal(id, likeable_type, listing_id)
    end
  end

  describe '#destroy' do
    it 'calls Pyramid::UsersResource#fire_delete' do
      listing_id = 123
      url = Pyramid::UsersResource.user_likeable_like_visibility_url(likeable_type, id, listing_id)
      Pyramid::UsersResource.expects(:fire_delete).with(url, is_a(Hash))
      Pyramid::User::Likes.hide(id, likeable_type, listing_id)
    end
  end
end
