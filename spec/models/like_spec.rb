require 'spec_helper'
require 'pyramid/models/like'

describe Pyramid::Like do
  describe '.save' do
    it 'works normally' do
      like = Fabricate(:listing_like)
      like.tombstone = true
      like.save
      like.reload
      like.tombstone.should be_true
    end
  end


  let!(:l1) { Fabricate(:listing_like) }
  let(:l2) { Fabricate(:listing_like, tombstone: true) }
  let(:l3) { Fabricate(:listing_like, visible: false) }
  let!(:l4) { Fabricate(:listing_like, deleted: true) }
  let!(:l5) { Fabricate(:listing_like, created_at: DateTime.now - 2) }
  let(:t1) { Fabricate(:tag_like) }
  let(:t2) { Fabricate(:tag_like, tombstone: true) }
  let(:t3) { Fabricate(:tag_like, visible: false) }
  let(:t4) { Fabricate(:tag_like, deleted: true) }

  describe '#counts_for_users' do
    it 'ignores invisible likes' do
      Pyramid::Like.counts_for_users([l1.user_id, l3.user_id, t1.user_id, t3.user_id]).should ==
        {l1.user_id => 1, t1.user_id => 1}
    end

    it 'ignores deleted likes' do
      Pyramid::Like.counts_for_users([l1.user_id, l4.user_id, t1.user_id, t4.user_id]).should ==
        {l1.user_id => 1, t1.user_id => 1}
    end
  end

  describe '#find_for_user' do
    it 'ignores invisible likes' do
      Pyramid::Like.find_for_user(l3.user_id).pagination_record_count.should == 0
    end

    it 'ignores deleted likes' do
      Pyramid::Like.find_for_user(l4.user_id).pagination_record_count.should == 0
    end
  end

  describe '#count_for_user' do
    it 'ignores invisible likes' do
      Pyramid::Like.count_for_user(l3.user_id).should == 0
    end

    it 'ignores deleted likes' do
      Pyramid::Like.count_for_user(l4.user_id).should == 0
    end
  end

  describe '#existences_for_user' do
    it 'ignores invisible likes' do
      Pyramid::Like.existences_for_user(t3.user_id, :tag, t3.tag_id).should == {}
    end

    it 'ignores deleted likes' do
      Pyramid::Like.existences_for_user(t4.user_id, :tag, t4.tag_id).should == {}
    end
  end

  describe '#get_for_user' do
    it 'ignores invisible like' do
      Pyramid::Like.get_for_user(t3.user_id, :tag, t3.tag_id).should be_nil
    end

    it 'returns invisible like when asked' do
      Pyramid::Like.get_for_user(t3.user_id, :tag, t3.tag_id, ignore_visibility: true).should == t3
    end

    it 'ignores deleted like' do
      Pyramid::Like.get_for_user(t4.user_id, :tag, t4.tag_id).should be_nil
    end

    it 'returns deleted like when asked' do
      Pyramid::Like.get_for_user(t4.user_id, :tag, t4.tag_id, ignore_deleted: true).should == t4
    end
  end

  describe '#count_for_likeable' do
    it 'ignores invisible likes' do
      Pyramid::Like.count_for_likeable(:listing, l3.listing_id).should == 0
    end

    it 'ignores deleted likes' do
      Pyramid::Like.count_for_likeable(:listing, l4.listing_id).should == 0
    end
  end

  describe '#find_for_likeable' do
    it 'ignores invisible likes' do
      Pyramid::Like.find_for_likeable(:listing, l3.listing_id).pagination_record_count.should == 0
    end

    it 'ignores deleted likes' do
      Pyramid::Like.find_for_likeable(:listing, l4.listing_id).pagination_record_count.should == 0
    end
  end

  describe '#counts_for_likeables' do
    it 'ignores invisible likes' do
      Pyramid::Like.counts_for_likeables(:listing, [l1.listing_id, l3.listing_id]).should ==
        {l1.listing_id => 1}
    end

    it 'ignores deleted likes' do
      Pyramid::Like.counts_for_likeables(:listing, [l1.listing_id, l4.listing_id]).should ==
        {l1.listing_id => 1}
    end
  end

  describe '#hot_or_not_suggestions_for_user' do
    let!(:me) { 1 }
    let!(:someone_else) { 2 }
    let!(:something_i_have_liked) { 1 }
    let!(:something_someone_else_has_liked) { 2 }
    let!(:something_else_someone_else_has_liked) { 3 }
    let!(:something_we_have_both_liked) { 4 }
    let!(:l1) { Fabricate(:listing_like, user_id: me, listing_id: something_i_have_liked) }
    let!(:l2) { Fabricate(:listing_like, user_id: someone_else, listing_id: something_someone_else_has_liked) }
    let!(:l3) { Fabricate(:listing_like, user_id: someone_else, listing_id: something_else_someone_else_has_liked) }
    let!(:l4) { Fabricate(:listing_like, user_id: me, listing_id: something_we_have_both_liked) }
    let!(:l5) { Fabricate(:listing_like, user_id: someone_else, listing_id: something_we_have_both_liked) }

    it "should return things I haven't liked that have been liked by people who have liked things I have liked" do
      expect(Pyramid::Like.hot_or_not_suggestions_for_user(me)).to include(something_someone_else_has_liked)
      expect(Pyramid::Like.hot_or_not_suggestions_for_user(me)).to include(something_else_someone_else_has_liked)
      expect(Pyramid::Like.hot_or_not_suggestions_for_user(me)).to_not include(something_we_have_both_liked)
      expect(Pyramid::Like.hot_or_not_suggestions_for_user(me)).to_not include(something_i_have_liked)
    end
  end

  describe '#recent_for_likeable' do
    let(:options) { {} }
    let(:results) { Pyramid::Like.recent_for_likeable(:listing, 1, options).map(&:values) }
    subject { results.map { |r| r[:listing_id] } }

    it 'returns in date range likes' do
      expect(subject).to include(l1.listing_id)
    end

    it 'ignores out of date range likes' do
      expect(subject).to_not include(l5.listing_id)
    end

    it 'ignores deleted likes' do
      expect(subject).to_not include(l4.listing_id)
    end

    context 'with user id filter ' do
      let(:options) { {exclude_liked_by_users: [l1.user_id]} }

      it 'only returns likes by unfiltered users' do
        expect(subject).to_not include(l1.listing_id)
      end

      it 'only does not return likes for listings that have been liked by filtered users' do
        like_from_other_user = Fabricate(:listing_like, listing_id: l1.listing_id)
        expect(subject).to_not include(like_from_other_user.listing_id)
      end
    end

    context 'with listing id filter' do
      let!(:l6) { Fabricate(:listing_like) }
      let(:options) { {ids: [l6.listing_id]} }

      it 'only returns listings that match the provided ids' do
        expect(subject).to include(l6.listing_id)
        expect(subject).to_not include(l1.listing_id)
      end
    end

    context 'when requesting counts' do
      let(:options) { {counts: 'true'} }
      subject { results }

      it 'includes counts in response' do
        expect(subject).to include({listing_id: l1.listing_id, count: 1})
      end
    end
  end

  describe '::delete_all_for_user' do
    let(:user_id) { 12345 }
    let!(:l1) { Fabricate(:listing_like, user_id: user_id) }
    let!(:l2) { Fabricate(:listing_like, user_id: user_id, tombstone: true) }
    let!(:l3) { Fabricate(:listing_like, user_id: user_id, visible: false) }
    let!(:l4) { Fabricate(:listing_like, user_id: user_id, deleted: true) }
    let!(:t1) { Fabricate(:tag_like, user_id: user_id) }
    let!(:t2) { Fabricate(:tag_like, user_id: user_id, tombstone: true) }
    let!(:t3) { Fabricate(:tag_like, user_id: user_id, visible: false) }
    let!(:t4) { Fabricate(:tag_like, user_id: user_id, deleted: true) }

    before { Pyramid::Like.delete_all_for_user(user_id) }

    it 'deletes with extreme prejudice' do
      expect(Pyramid::Like.where(user_id: user_id).count).to eq(0)
    end
  end
end
