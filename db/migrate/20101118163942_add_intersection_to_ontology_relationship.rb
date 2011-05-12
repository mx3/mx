class AddIntersectionToOntologyRelationship < ActiveRecord::Migration
  def self.up
    add_column :ontology_relationships, :is_intersection, :boolean, :default => false
  end

  def self.down
    remove_column :ontology_relationships, :is_intersection
  end
end
