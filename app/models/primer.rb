# == Schema Information
# Schema version: 20090930163041
#
# Table name: primers
#
#  id            :integer(4)      not null, primary key
#  gene_id       :integer(4)
#  name          :string(64)
#  sequence      :string(255)
#  regex         :string(255)
#  ref_id        :integer(4)
#  protocol_id   :integer(4)
#  notes         :text
#  designed_by   :string(255)
#  target_otu_id :integer(4)
#  proj_id       :integer(4)      not null
#  creator_id    :integer(4)      not null
#  updator_id    :integer(4)      not null
#  updated_on    :timestamp       not null
#  created_on    :timestamp       not null
#

class Primer < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::DefaultNamedScopes

  has_many :tags, :as => :addressable 
  belongs_to :gene # can be independant
  belongs_to :proj
  belongs_to :ref 
  belongs_to :target_otu, :class_name => "Otu", :foreign_key => "target_otu_id"
  
  has_many :chromatograms
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => 'proj_id'
  validates_uniqueness_of :sequence, :scope => 'proj_id'
  validates_presence_of :sequence
  # validates_presence_of :gene

  def display_name(options = {})
    name
  end  

  def gene_name
    gene ? gene.name : 'not tied to gene'
  end

end
