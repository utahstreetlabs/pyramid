require 'sequel'

Sequel.migration do
  change do
    create_table :likes do
      primary_key :id

      Time :created_at, null: false
      Time :updated_at, null: false

      Integer :user_id, null: false
      Integer :listing_id
      Integer :tag_id

      index :listing_id
      index :tag_id
      index :user_id
    end
  end
end
