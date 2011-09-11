class Differentia < ActiveRecord::Base
    
  belongs_to :property, :class_name => "OntologyTerm"
  belongs_to :value, :polymorphic => true   # might not be legit in Rails 3
  belongs_to :ontology_composition
  
  def Differentia.available_properties
    ObjectRelationship.ontology_relations.collect do |relation|
      term = OntologyTerm.find_or_create_by_uri(Ontology::OntologyMethods.obo_uri(relation))
      term.label = relation.interaction
      term.save
      term
    end
  end
  
end