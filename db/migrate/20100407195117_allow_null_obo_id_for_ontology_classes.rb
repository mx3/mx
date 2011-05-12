class AllowNullOboIdForOntologyClasses < ActiveRecord::Migration
  def self.up 
    
    change_column :ontology_classes, :obo_label_id, :integer, :null => true, :limit => 11, :default => nil
    
  end

  def self.down
  end
end
