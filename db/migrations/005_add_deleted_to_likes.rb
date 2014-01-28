require 'sequel'

Sequel.migration do
  change do
    add_column :likes, :deleted, FalseClass, default: false
  end
end
