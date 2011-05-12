# == Schema Information
# Schema version: 20090930163041
#
# Table name: specimen_determinations
#
#  id                  :integer(4)      not null, primary key
#  specimen_id         :integer(4)
#  otu_id              :integer(4)
#  current_det         :boolean(1)      default(TRUE)
#  determiner          :string(255)
#  name                :string(255)
#  det_year            :string(4)  # NOW det_on datetime
#  confidence_id       :integer(4)
#  determination_basis :string(255)
#  creator_id          :integer(4)      not null
#  updator_id          :integer(4)      not null
#  updated_on          :timestamp       not null
#  created_on          :timestamp       not null
#

class SpecimenDetermination < ActiveRecord::Base
  has_standard_fields
  belongs_to :specimen
  belongs_to :otu
  belongs_to :confidence
  
  # has_many :image_descriptions # TODO: this was deprecated - perhaps revisit as a feature request 

  scope :ordered_by_determination_year, :order => 'det_on DESC, created_on DESC'

  validates_presence_of :specimen, :det_on # if year not provided taken from created_on
  before_validation :set_det_on_if_needed

  validate :check_record
  def check_record # require either otu or name
    if self.otu_id.blank? and self.name.blank?
      errors.add(:otu_id, 'must supply either name or OTU')
    end
  end

  def display_name(options = {})
    opt = {
      :type => :line 
    }.merge!(options.symbolize_keys)
    s = ''
    case opt[:type]
    when :selected
      if self.otu
        s << self.otu.display_name 
      else 
        s << self.name
      end
    when :for_select_list
      s <<  (otu_id ? "#{self.otu.display_name(:type => :for_select_list)}" : "#{name}") +  (self.determiner? ? " by: #{determiner}"  : "")
    when :with_OTU_id_when_present
      if self.otu
        s << self.otu.display_name + " (OTU id: #{self.otu.id})"
      else 
        s << self.name
      end
    else
      s = ''
      s +=  (otu_id ? self.otu.display_name(:type => :multi_name) : '') # + " <span class=\"small_grey\">(OTU id:" + otu_id.to_s + ")</span>") : self.name)
      s +=  (name ? self.name : '')
      s +=  " <span class='small_grey'>by: #{self.determiner.blank? ? self.creator.andand.full_name : self.determiner} </span>" 
      s +=  " <span class='small_grey'>, based on #{self.determination_basis} </span>" if self.determination_basis?
      s +=  " <span class='small_grey'>, with confidence #{self.confidence.display_name} </span>" if self.confidence_id?
    end
    s.html_safe
  end

  def identified_by
    determiner.blank? ? self.creator.full_name : determiner
  end

  # TODO: constantize 
  def self.basises
    ['comparison with holotype',  'comparison with paratype', 'comparison with original description', 'other...']
  end

  protected

  def set_det_on_if_needed 
    self.det_on ||= Time.now
  end

end
