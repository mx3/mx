class FormalizeTagsByAddingReferencedObjectField < ActiveRecord::Migration
  def self.up
    add_column :tags, :referenced_object, :string
    add_index :tags, :referenced_object
  end

  def self.down
    remove_index :tags, :referenced_object, :string
    remove_column :tags, :referenced_object
  end
end
