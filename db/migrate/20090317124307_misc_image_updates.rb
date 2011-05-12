class MiscImageUpdates < ActiveRecord::Migration
  def self.up
    add_column :images, :copyright_holder, :string
    add_column :images, :contributor, :string
    add_column :standard_views, :identifier, :string
    add_column :standard_views, :namespace_id, :integer # in combination with identifier
    add_column :image_descriptions, :magnification, :string, :limit => 255

    execute %{ ALTER TABLE standard_views ADD CONSTRAINT `standard_views_namespace_fk` FOREIGN KEY  (namespace_id) REFERENCES namespaces(id); }
    
  end

  def self.down
    remove_column :images, :copyright_holder
    remove_column :images, :contributor
    
    execute %{ ALTER TABLE standard_views DROP FOREIGN KEY standard_views_namespace_fk; }

    remove_column :standard_views, :identifier
    remove_column :standard_views, :namespace_id
    remove_column :image_descriptions, :magnification


  end

end
