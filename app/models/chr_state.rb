# == Schema Information
# Schema version: 20090930163041
#
# Table name: chr_states
#
#  id               :integer(4)      not null, primary key
#  chr_id           :integer(4)      not null
#  state            :string(8)       not null
#  name             :string(255)
#  cited_polarity   :string(15)      default("none")
#  hh_id            :integer(4)
#  revision_history :text
#  notes            :text
#  creator_id       :integer(4)      not null
#  updator_id       :integer(4)      not null
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null
#

class ChrState < ActiveRecord::Base
  # This model doesn't not have its own controller, methods are handles in the ChrController
  has_standard_fields

  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  has_many :codings, :dependent => :destroy
  has_many :otus, :through => :codings 

  belongs_to :chr
  belongs_to :phenotype, :polymorphic => true

 # TODO: build these 
 # scope :in_matrix, lambda {|*args| {:include => [:chr, :chrs_mxes]:conditions => "ontology_classes.id NOT IN (SELECT ontology_class1_id from ontology_relationships) AND ontology_classes.id NOT IN (SELECT ontology_class2_id from ontology_relationships)" }} 
  # has_many :mxes, :finder_sql = 'Select m.* from mxes m JOIN chrs_mxes cm on cm.mx_id = m.id JOIN chrs c on cm.chr_id = c.id JOIN  cs.* from chr_states cs JOIN chrs_mxes cm on cm.chr_id = cs.id

  validates_presence_of :state
  validates_uniqueness_of :state, :scope => "chr_id"
  before_validation :polarity_null_thing

  # TODO: before save update non-normalized fields in Codings

  def polarity_null_thing
    write_attribute("cited_polarity", nil) if cited_polarity == ""
  end
 
  def display_name(options = {})
    name
  end

  def self.cited_polarities
    ['','none','plesiomorphic','apomorphic','ambiguous']
  end
  
  def s_and_m 
    state + ": " + name
  end
  
  def coded?(otu_id)
    Coding.find_by_chr_state_id_and_otu_id(id, otu_id)
  end

  # TODO: DEPRECATE for has_many, :limit
  def example_otus
    Otu.find_by_sql(["SELECT codings.chr_state_id, otus.*
      FROM otus INNER JOIN codings ON otus.id = codings.otu_id WHERE (codings.chr_state_id = ?) ORDER BY otus.name LIMIT 5;", self.id])
  end

  # TODO: DEPRECATE for has_many
  def all_otus
    Otu.find_by_sql(["SELECT codings.chr_state_id, otus.*
      FROM otus INNER JOIN codings ON otus.id = codings.otu_id WHERE (codings.chr_state_id = ?) ORDER BY otus.name", self.id])
  end
  
  
end
