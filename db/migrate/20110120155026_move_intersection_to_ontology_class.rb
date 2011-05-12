class MoveIntersectionToOntologyClass < ActiveRecord::Migration
  def self.up
    #assuming nobody has used this column in practice
    remove_column :ontology_relationships, :is_intersection
    add_column :ontology_classes, :relationships_are_sufficient, :boolean, :default => false
  end

  def self.down
    remove_column :ontology_classes, :relationships_are_sufficient
    add_column :ontology_relationships, :is_intersection, :boolean, :default => false
  end
end
