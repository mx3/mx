class AddPropertiesToRelations < ActiveRecord::Migration
  def self.up
    add_column :object_relationships, :is_symmetric, :boolean, :default => false
    add_column :object_relationships, :is_irreflexive, :boolean, :default => false
  end

  def self.down
    remove_column :object_relationships, :is_symmetric
    remove_column :object_relationships, :is_irreflexive
  end
end
