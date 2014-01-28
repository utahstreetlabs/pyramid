Fabricator(:like, from: :'pyramid/like') do
  id { sequence :like_id, 1 }
  user_id { sequence :user_id, 1 }
  tombstone false
  visible true
end

Fabricator(:listing_like, from: :like) do
  listing_id { sequence :listing_id, 1 }
end

Fabricator(:tag_like, from: :like) do
  tag_id { sequence :tag_id, 1 }
end
