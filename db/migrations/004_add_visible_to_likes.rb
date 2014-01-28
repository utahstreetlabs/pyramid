require 'sequel'

Sequel.migration do
  change do
    add_column :likes, :visible, TrueClass, default: true
  end
end
