class UpdateViewsMeasurementsEtcToUseOntologyClasses < ActiveRecord::Migration
  def self.up
    
    add_column :standard_views, :ontology_class_id, :integer, :size => 11, :null => true, :references => :ontology_classes
    add_column :standard_views, :formula, :text, :null => true
    
    # map characters to continuous states
    add_column :chrs, :standard_view_id, :integer, :size => 11, :null => true, :references => :standard_views
    
    # come cleanup
    remove_column :standard_views, :part_id
    remove_column :chrs, :continuous         
  end

  def self.down
    # not reversible
  end
end
