class TweakIndexesOnTags < ActiveRecord::Migration
  def self.up
    remove_index :tags, :name => 'keyword_id'
    add_index :tags, [:addressable_id, :addressable_type], :name => "addressable"
    add_index :tags, [:addressable_id, :addressable_type, :keyword_id], :name => "addressable_with_keywords"
    add_index :tags, [:addressable_id, :addressable_type, :keyword_id, :ref_id], :name => 'all_minus_proj'
    add_index :tags, [:addressable_id, :addressable_type, :keyword_id, :proj_id, :ref_id], :name => 'all'
  end

  def self.down
     add_index :tags, [:addressable_id, :addressable_type, :keyword_id, :ref_id], :name => "keyword_id", :unique => true
     remove_index :tags, :name => 'addressable'
     remove_index :tags, :name => 'addressable_with_keywords'
     remove_index :tags, :name => 'all_minus_proj'
     remove_index :tags, :name => 'all'
  end
end
