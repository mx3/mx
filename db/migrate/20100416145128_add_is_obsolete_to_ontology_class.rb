class AddIsObsoleteToOntologyClass < ActiveRecord::Migration
  def self.up
    add_column :ontology_classes, :is_obsolete, :boolean, :default => false
  end

  def self.down
    drop_column :ontology_classes, :is_obsolete
  end
end
