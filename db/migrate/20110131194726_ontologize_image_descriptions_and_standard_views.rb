class OntologizeImageDescriptionsAndStandardViews < ActiveRecord::Migration
  def self.up
    remove_index :standard_view_groups, :name => :name
    remove_column :standard_views, :ontology_class_id
    
    remove_column :standard_views, :namespace_id
    remove_column :standard_views, :identifier
    
    add_column :image_descriptions, :ontology_class_dbxref, :string, :null => true
    add_index  :image_descriptions, :ontology_class_dbxref
   
    add_column :standard_views, :ontology_class_dbxref, :string, :null => true
    add_index :standard_views, :ontology_class_dbxref
    
    change_column :standard_view_groups, :name, :string, :null => false, :unique => false
    change_column :standard_views, :image_view_id, :integer, :null => true, :size => 11, :references => :image_views
  end

  def self.down
  
   add_column :standard_views, :identifier, :integer  
   add_column :standard_views, :namespace_id, :integer, :size => 11, :references => :namespaces
    
   add_index :standard_view_groups, :name, :name => :name
   add_column :standard_views, :ontology_class_id, :integer, :size => 11, :references => :ontology_classes
   remove_column :standard_views, :ontology_class_dbxref
   remove_column :image_descriptions, :ontology_class_dbxref
  end
end
