# == Schema Information
# Schema version: 20090930163041
#
# Table name: distributions
#
#  id            :integer(4)      not null, primary key
#  geog_id       :integer(4)
#  otu_id        :integer(4)
#  ref_id        :integer(4)
#  confidence_id :integer(4)
#  verbatim_geog :string(255)
#  introduced    :boolean(1)               # NOW integer
#  num_specimens :integer(4)      not null # DEPRECATED
#  notes         :text
#  proj_id       :integer(4)      not null
#  creator_id    :integer(4)      not null
#  updator_id    :integer(4)      not null
#  updated_on    :timestamp       not null
#  created_on    :timestamp       not null
#


# Records extracted from the literature, these data are here not tied to specimens or collecting events
class Distribution < ActiveRecord::Base

  include ModelExtensions::DefaultNamedScopes

  STATUS = [[:native, 0], [:introduced, 1], [:unknown, 2]] # populates Distribution##introduced

  has_standard_fields
  belongs_to :otu
  belongs_to :ref
  belongs_to :confidence
  belongs_to :geog

  validates_presence_of :otu, :ref, :geog
 
  scope :native, :include => :geog, :order => 'geogs.name, distributions.verbatim_geog', :conditions => 'introduced = 0'
  scope :introduced, :include => :geog, :order => 'geogs.name, distributions.verbatim_geog', :conditions => 'introduced = 1'
  scope :unclassified, :include => :geog, :order => 'geogs.name, distributions.verbatim_geog', :conditions => 'introduced = null'
  scope :ordered_by_geog_name, :include => :geog, :order => 'geogs.name, distributions.verbatim_geog'
  scope :using_geogs, :conditions => 'geog_id is not null'

  def display_name(options = {})
    otu.display_name + " / " + ref.authors_year + " / " + geog.display_name
  end

  def display_introduced
    case introduced
    when 0
      "native"
    when 1
      "introduced"
    when 2
      "unknown"
    else
      "not provided"
    end
  end

end
