class AddDefaultOntologyTermIdToProjs < ActiveRecord::Migration
  def self.up
    add_column :projs, :default_ontology_term_id, :integer, :references => :parts, :foreign_key => 'id'
    add_index :projs, :default_ontology_term_id
  end

  def self.down
    remove_index :projs, :default_ontology_term_id
    remove_column :projs, :default_ontology_term_id
  end
end
