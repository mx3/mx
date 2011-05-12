# == Schema Information
# Schema version: 20090930163041
#
# Table name: geogs
#
#  id                         :integer(4)      not null, primary key
#  name                       :string(255)     not null
#  abbreviation               :string(64)
#  fips_code                  :integer(4)
#  sort_NS                    :integer(4)
#  sort_WE                    :integer(4)
#  center_lat                 :string(64)
#  center_long                :string(64)
#  geog_type_id               :integer(4)
#  inclusive_biogeo_region_id :integer(4)
#  country_id                 :integer(4)
#  state_id                   :integer(4)
#  county_id                  :integer(4)
#  continent_ocean_id         :integer(4)
#  namespace_id               :integer(4)
#  external_id                :integer(4)
#  creator_id                 :integer(4)      not null
#  updator_id                 :integer(4)      not null
#  updated_on                 :timestamp       not null
#  created_on                 :timestamp       not null
#

class Geog < ActiveRecord::Base
  has_standard_fields
  belongs_to :geog_type
  belongs_to :country,  :class_name => "Geog", :foreign_key => "country_id"
  belongs_to :state, :class_name => "Geog", :foreign_key => "state_id"  
  belongs_to :county, :class_name => "Geog",:foreign_key => "county_id"  
  belongs_to :continent_ocean, :class_name => "Geog", :foreign_key => "continent_ocean_id"  
  belongs_to :biogeo_region, :class_name => "Geog",:foreign_key => "inclusive_biogeo_region_id"    

  has_many :ces
  has_many :tags, :as => :addressable, :dependent => :destroy, :include => [:keyword, :ref], :order => 'refs.cached_display_name ASC'  
  has_many :distributions
  has_many :otus, :through => :distributions

  validates_presence_of :geog_type_id
  validates_presence_of :name 

  def display_name(options = {}) # :yields: String
    opt = {
     :type => nil
    }.merge!(options.symbolize_keys)
    s = ''
    case opt[:type]
    when :selected
      name
    when :for_select_list
      s = name
      s << " [#{self.geog_type.name}]" if self.geog_type
      s << " #{self.country.name}" if (self.country and not self.geog_type.name == 'country')
      s
    else
      type_name = (self.geog_type ? self.geog_type.name : 'none')
      s = ''
      s << "#{self.country.name}: " if (self.country and type_name != 'country')
      s << "#{self.state.name}: " if (self.state_id and self.id != self.state_id) # may have a 'state', but type_name may be 'province'
      s << (type_name == 'county' ? self.name + " Co." : self.name)
    end
  end

  def country_string # :yields: String
    self.country ? self.country.name : 'not provided'
  end

  def state_string # :yields: String
    self.state ? self.state.name : 'not provided'
  end

  def county_string # :yields: String
    self.county ? self.county.name : 'not provided'
  end

  # sorting f(n)
  def country? # :yields: String
     country ? country.name : "AAAA#{name}" 
  end

  # TODO: proof of concept only 
  def self.detect_from_geocode(geocode)
    state = [geocode.state, geocode.province].compact.first 
    if g = Geog.find_by_name(state)
      return g
    elsif g = Geog.find_by_name(geocode.country)
      return g
    end
  end

end
