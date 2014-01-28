require 'sequel'

Sequel.migration do
  change do
    add_index :likes, [:user_id, :listing_id], unique: true
    add_index :likes, [:user_id, :tag_id], unique: true
  end
end
