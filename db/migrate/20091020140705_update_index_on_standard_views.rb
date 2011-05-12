class UpdateIndexOnStandardViews < ActiveRecord::Migration
  def self.up
    remove_index :standard_views, :name => 'proj_id'
    remove_index :standard_views, :name => 'name'
    add_index(:standard_views, [:name, :proj_id], :name => 'name', :unique => true)
  end

  def self.down
    remove_index :standard_views, :name => 'name'
    add_index(:standard_views, [:proj_id, :part_id, :image_view_id], :name => 'proj_id', :unique => true)
    add_index(:standard_views, [:name], :name => 'name', :unique => true)
  end
  
end
