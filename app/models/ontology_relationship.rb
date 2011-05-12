class OntologyRelationship < ActiveRecord::Base
  require 'obo_parser'
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  OBO_TYPEDEFS = ['is_a', 'disjoint_from', 'instance_of', 'inverse_of', 'union_of', 'intersection_of']

  belongs_to :ontology_class1, :foreign_key => 'ontology_class1_id', :class_name => 'OntologyClass'
  belongs_to :ontology_class2, :foreign_key => 'ontology_class2_id', :class_name => 'OntologyClass'
  belongs_to :object_relationship

  scope :by_object_relationship, lambda {|*args| {:conditions => ["object_relationship_id = ?",  (args.first || -1)]}}
  scope :by_object_relationship_name, lambda {|*args| {:conditions => ["object_relationships.interaction = ?",  (args.first || -1)], :include => :object_relationship}}
  scope :where_both_ontology_classes_have_xrefs, :joins => 'JOIN (ontology_classes oc1, ontology_classes oc2) ON (oc1.id = ontology_class1_id AND oc2.id = ontology_class2_id)', :conditions => 'oc1.xref is not null and oc1.xref != "" AND oc2.xref is not null and oc2.xref != ""' 
  scope :with_ontology_class, lambda{|id| {:conditions => ["ontology_class1_id = ? OR ontology_class2_id = ?", id, id]}}

  validates_presence_of :ontology_class1, :ontology_class2, :object_relationship

  validate :check_record
  def check_record
    if OntologyRelationship.find_by_ontology_class1_id_and_ontology_class2_id_and_object_relationship_id(ontology_class1_id, ontology_class2_id, object_relationship_id)
      errors.add("The class relationship combination already exists, it therefor ")
    end
  end

  after_create :energize_create_relationship
  after_destroy :energize_destroy_relationship

  def energize_create_relationship
    [ontology_class1, ontology_class2].each do |o|
      o.labels.each do |l| 
        l.energize(creator_id, "created a relationship for a class labeled with")
        l.save!
      end 
    end
    true
  end

  def energize_destroy_relationship(person_id = $person_id)
    [ontology_class1, ontology_class2].each do |o|
      o.labels.each do |l| 
        l.energize(person_id, "destroyed a relationship for a class labeled with")
        l.save!
      end 
    end
    true
  end

  def display_name(options = {})
    ontology_class1.display_name + " " + object_relationship.display_name + " " + ontology_class2.display_name
  end

  # summarizes reference use in the Ontology
  # returns a Hash of {:key => [[Refs] ...] 
  def self.tied_references(options = {})
    return [] if !options[:proj_id]
    proj = Proj.find(options[:proj_id]) 
    result = { }

    result[:used_in_sensus] = proj.refs.used_in_sensus
    result[:used_in_ontology_class_written_by] = proj.refs.used_in_ontology_class_written_by

    result[:used_on_tags_on_classes] = proj.ontology_classes.collect{|p| p.tags.collect{|t| (t.ref_id.blank? ? nil : t.ref)}}.flatten.compact.uniq.sort{|a,b| a.display_name <=> b.display_name}
    result[:used_on_tags_on_labels] =  proj.labels.collect{|p| p.tags.collect{|t| (t.ref_id.blank? ? nil : t.ref)}}.flatten.compact.uniq.sort{|a,b| a.display_name <=> b.display_name}
    result[:used_on_tags_on_sensus] =  proj.sensus.collect{|p| p.tags.collect{|t| (t.ref_id.blank? ? nil : t.ref)}}.flatten.compact.uniq.sort{|a,b| a.display_name <=> b.display_name}

    result[:all] = result.keys.collect{|k| @result[k]}.flatten.compact.uniq.sort{|a,b| a.display_name <=> b.display_name } 

    result
  end

  ## TODO: EVERYTHING BELOW SHOULD BE MOVED 

  # pass a Person
  # TODO: move to `include Roles` , or extend to all ActiveRecord
  def created_or_admin(person)
    if person.id.to_i == self.creator_id.to_i || person.is_admin
      true
    else
      false
    end
  end


end
