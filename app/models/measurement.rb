# == Schema Information
# Schema version: 20090930163041
#
# Table name: measurements
#
#  id                :integer(4)      not null, primary key
#  specimen_id       :integer(4)      not null
#  measurement       :float
#  standard_view_id  :integer(4)      not null
#  units             :string(12)
#  conversion_factor :float
#  proj_id           :integer(4)      not null
#  creator_id        :integer(4)      not null
#  updator_id        :integer(4)      not null
#  updated_on        :timestamp       not null
#  created_on        :timestamp       not null
#

class Measurement < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::DefaultNamedScopes

  belongs_to :specimen
  belongs_to :standard_view

  validates_presence_of :standard_view_id
  validates_presence_of :specimen_id
  validates_presence_of :measurement 
  validates_presence_of :units
  validates_uniqueness_of :specimen_id, :scope => :standard_view_id, :message => "measurement has already been made."

  before_update :check_conversion_factor

  scope :by_standard_view, lambda {|*args| {:conditions => ["standard_view_id = ?", (args.first || -1)] }}
  scope :by_units, lambda {|*args| {:conditions => ["units = ?", (args.first || -1)] }}
  scope :by_conversion_factor, lambda {|*args| {:conditions => ["conversion_factor = ?", (args.first || -1)] }}

  def display_name(options = {})
    conversion_factor.to_f * measurement.to_f
  end

  def check_conversion_factor
    conversion_factor = 1 if conversion_factor.blank?
    true
  end

end
