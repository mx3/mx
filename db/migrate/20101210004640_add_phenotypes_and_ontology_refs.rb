class AddPhenotypesAndOntologyRefs < ActiveRecord::Migration
  
  def self.up
    create_table :phenotypes do |table|
      table.string :type
      
      # common Phenotype attributes
      table.integer :entity_id, :references => nil, :size => 11 # OntologyTerm or OntologyComposition
      table.string :entity_type # OntologyTerm or OntologyComposition
      
      # common CardinalPhenotype attributes (PresenceAbsence & Count)
      table.integer :within_entity_id, :references => nil, :size => 11 # OntologyTerm or OntologyComposition
      table.string :within_entity_type # OntologyTerm or OntologyComposition
      
      # attributes for type=PresenceAbsencePhenotype
      table.boolean :is_present
      
      # attributes for type=CountPhenotype
      table.integer :minimum
      table.integer :maximum
      
      # attributes for type=QualitativePhenotype
      table.integer :quality_id, :references => nil, :size => 11 # OntologyTerm or OntologyComposition
      table.string :quality_type # OntologyTerm or OntologyComposition
      table.integer :dependent_entity_id, :references => nil, :size => 11 # OntologyTerm or OntologyComposition
      table.string :dependent_entity_type # OntologyTerm or OntologyComposition
    end
    
    create_table :ontology_terms do |table|
      table.string :uri, :null => false
      table.string :label
      table.string :bioportal_ontology_identifier
      # more?
    end
    
    create_table :ontology_compositions do |table|
      table.integer :genus_id, :null => false, :references => :ontology_terms, :size => 11 # OntologyTerm
    end
    
    create_table :differentiae do |table|
      table.integer :property_id, :null => false, :references => :ontology_terms, :size => 11 # OntologyTerm
      table.integer :value_id, :null => false, :references => nil, :size => 11 # OntologyTerm or OntologyComposition
      table.string :value_type, :null => false # OntologyTerm or OntologyComposition
      table.integer :ontology_composition_id, :null => false, :size => 11 # enclosing OntologyComposition
    end
    
  end

  def self.down
    drop_table :differentiae
    drop_table :ontology_compositions
    drop_table :ontology_terms
    drop_table :phenotypes
  end
  
end
