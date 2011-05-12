class AddProportionalPhenotype < ActiveRecord::Migration
  def self.up
    add_column :phenotypes, :relative_proportion, :float
    add_column :phenotypes, :relative_magnitude, :string
    add_column :phenotypes, :relative_entity_id, :integer, :references => nil, :size => 11 # OntologyTerm or OntologyComposition
    add_column :phenotypes, :relative_entity_type, :string # OntologyTerm or OntologyComposition
    add_column :phenotypes, :relative_quality_id, :integer, :references => nil, :size => 11 # OntologyTerm or OntologyComposition
    add_column :phenotypes, :relative_quality_type, :string # OntologyTerm or OntologyComposition
  end

  def self.down
    remove_column :phenotypes, :relative_proportion
    remove_column :phenotypes, :relative_magnitude
    remove_column :phenotypes, :relative_entity_id
    remove_column :phenotypes, :relative_entity_type
    remove_column :phenotypes, :relative_quality_id
    remove_column :phenotypes, :relative_quality_type
  end
  
end
