require 'sequel'

Sequel.migration do
  change do
    add_column :likes, :tombstone, TrueClass, default: false
    # not adding indexes with tombstones since Rob says mysql is fast enough without them!
  end
end
