class IsPublicifyForIpt < ActiveRecord::Migration
  def self.up
    add_column :specimens, :is_public, :boolean, :default => true
    add_column :lots, :is_public, :boolean, :default => true
    add_column :ces, :is_public, :boolean, :default => true
    add_column :projs, :is_exportable_to_gbif, :boolean, :default => false
  end

  def self.down
    remove_column :specimens, :is_public
    remove_column :lots, :is_public    
    remove_column :ces, :is_public
    remove_column :projs, :is_exportable_to_gbif
  end
  
end
