# == Schema Information
# Schema version: 20090930163041
#
# Table name: lots
#
#  id              :integer(4)      not null, primary key
#  otu_id          :integer(4)      not null
#  key_specimens   :integer(4)      default(0), not null
#  value_specimens :integer(4)      default(0), not null
#  ce_id           :integer(4)
#  ce_labels       :text
#  rarity          :string(16)
#  source_quality  :string(16)
#  notes           :text
#  repository_id   :integer(4)
#  dna_usable      :boolean(1)      default(TRUE)
#  mixed_lot       :boolean(1)
#  sex             :string(64)
#  proj_id         :integer(4)      not null
#  creator_id      :integer(4)      not null
#  updator_id      :integer(4)      not null
#  updated_on      :timestamp       not null
#  created_on      :timestamp       not null
#  stage           :string(255)
#

class Lot < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::Taggable
  include ModelExtensions::DefaultNamedScopes
  # should be Figurable? 
  include ModelExtensions::MiscMethods
  include ModelExtensions::Identifiable

  belongs_to :otu
  belongs_to :repository
  belongs_to :ce 
  belongs_to :preparation, :foreign_key => :preparation_protocol_id, :class_name => 'Protocol'

  has_one :ipt_record, :dependent => :destroy
  has_many :extracts, :dependent => :destroy
  has_many :lot_identifiers, :dependent => :delete_all # TODO: deprecate

  has_and_belongs_to_many :lot_groups

  scope :with_usable_dna, :conditions => {:dna_usable => true} 
  scope :determined_as_otu, lambda {|*args| {:conditions => ["lots.otu_id = ?", (args.first || -1)] }}
  scope :member_of_taxon, lambda {|*args| {:include => [{:otu => :taxon_name}], :conditions => ['taxon_names.l >= ? and taxon_names.r <= ?', (args.first.l || -1), (args.first.r || -1)] }}
  scope :with_value_specimens, :conditions => 'lots.value_specimens > 0'
  scope :include_has_manys, :include => [:repository, :ce, :otu, :creator, :updator]

  validates_presence_of :otu, :key_specimens, :value_specimens
  validates_length_of :rarity, :maximum => 16, :allow_nil => true, :message=>"must be %d or fewer characters"
  validates_length_of :source_quality, :maximum => 16, :allow_nil => true, :message=>"must be %d or fewer characters"

  validate(:on => :create) do
    if (key_specimens == 0) and (value_specimens == 0)
      errors.add(:key_specimens, "- now that's a whole LOT of nothing!")
    end
  end
  
  def display_name(options = {})
    opt = {
      :type => :selected 
    }.merge!(options.symbolize_keys)
    
    case opt[:type]
    when :identifiers
      return 'none' if identifiers.count == 0
      s = identifiers.map(&:cached_display_name).join("; ")
    when :determination
      s =  self.otu.display_name
    when :in_list
      s = "#{otu.display_name(:type => :in_list)}" + " " + self.display_name(:type => :identifiers)
    when :for_select_list
      s = "#{self.display_name(:type => :identifiers)} : #{otu.display_name(:type => :for_select_list)} <span style='color:grey;font-size:smaller;'>mx_id:#{id.to_s}</span>"
    when :selected
      s = "#{self.display_name(:type => :identifiers)} / #{otu.display_name(:type => :selected)} (#{id})"
    else
      s = self.display_name(:type => :identifiers) == 'none' ? "#{self.id}" : self.display_name(:type => :identifiers) + " " + otu.display_name(:type => :multi_name)
    end
    s.html_safe
  end
  
  def self.find_for_auto_complete(value)
    find_by_sql [
      "SELECT l.* FROM lots l
        LEFT JOIN identifiers i ON l.id = i.addressable_id
        LEFT JOIN otus o ON l.otu_id = o.id 
        LEFT JOIN taxon_names t ON o.taxon_name_id = t.id 
        WHERE o.proj_id = #{$proj_id}
        AND i.addressable_type = 'Lot'
        AND (o.name LIKE ? OR
        o.matrix_name LIKE ? OR
        t.name LIKE ? OR
        i.identifier LIKE ? OR
        l.id = ?) LIMIT 30",
      "#{value.downcase}%", "#{value.downcase}%", "#{value.downcase}%", "%#{value.downcase}%", "#{value}"]
  end
 
  def total_specimens
    key_specimens + value_specimens
  end

  def divide(params) # :yields: Lot || nil
    # takes params from lots/_divide_form
    return nil if params[:key].blank? && params[:value].blank?
    return nil if params[:key].to_i == 0 && params[:value].to_i == 0
     
    self.key_specimens = self.key_specimens - params[:key].to_i
    self.value_specimens = self.value_specimens - params[:value].to_i
    self.save

    l = self.make_clone
    l.key_specimens = params[:key].to_i
    l.value_specimens = params[:value].to_i
    l.save
    l

  end 

  def make_clone # :yields: a Lot
    # $person_id and $specimen_id must be nil
    l = self.clone
    l.created_on = Time.now
    l.updated_on = Time.now
    
    l.save
    l.identifiers.destroy_all

    l
  end
end
