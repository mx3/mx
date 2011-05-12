class OntologyComposition < ActiveRecord::Base
  
  belongs_to :genus, :class_name => "OntologyTerm"
  has_many :differentiae
  
end