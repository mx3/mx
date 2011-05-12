class MakeProjsRefsAModelWithPosition < ActiveRecord::Migration
  def self.up
    add_column :projs_refs, :id, :primary_key
    add_column :projs_refs, :position, :integer
    add_index :projs_refs, [:proj_id, :ref_id], :unique => true, :name => 'projs_refs_index'
  end

  def self.down
    remove_index :projs_refs, :name => :projs_refs_index
    remove_column :projs_refs, :id
    remove_column :projs_refs, :position
  end
end
