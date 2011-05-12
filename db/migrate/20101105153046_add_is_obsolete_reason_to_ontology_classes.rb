class AddIsObsoleteReasonToOntologyClasses < ActiveRecord::Migration
  def self.up
    add_column :ontology_classes, :is_obsolete_reason, :text
  end

  def self.down
    remove_column :ontology_classes, :is_obsolete_reason
  end
end
