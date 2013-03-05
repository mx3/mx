# == Schema Information
# Schema version: 20090930163041
#
# Table name: type_specimens
#
#  id            :integer(4)      not null, primary key
#  specimen_id   :integer(4)      not null
#  taxon_name_id :integer(4)      not null
#  type_type     :string(24)
#  notes         :text

class TypeSpecimen < ActiveRecord::Base
  self.table_name = 'type_specimens'
  belongs_to :specimen
  belongs_to :taxon_name
  belongs_to :ref
  belongs_to :otu

  scope :with_type_status, lambda {|*args| {:conditions => ["type_type = ?", (args.first || -1)] }}
  scope :without_taxon_name_assignment, :conditions => "specimen_id is null"
  scope :with_taxon_name_assignment, lambda {|*args| {:conditions => ["taxon_name_id = ?", (args.first || -1)] }}

  validates_uniqueness_of :specimen_id, :scope => :taxon_name_id, :allow_nil => true
  validates_presence_of :type_type
  validates_presence_of :specimen

  validate :check_record
  def check_record
    if self.taxon_name_id.blank? && self.otu_id.blank?
      errors.add(:taxon_name_id, 'Must link to a taxon name or an undescribed taxon through OTU.')
    end
    errors.add(:taxon_name, "Type specimens only apply to species group names.") if self.taxon_name && self.taxon_name.iczn_group != 'species' 
  end

  def display_name(options = {})
    s = "#{type_type} of " 
    if taxon_name
      s << "#{taxon_name.display_name(:type => :string_no_author_year)}."
    else
      if @public 
        s << " Unpublished taxon." 
      else
        s << " Unpublished taxon #{otu.manuscript_name}."
      end
    end 

    if ref
      s << " " + ref.display_name
    elsif taxon_name
      s << " " + (taxon_name.ref ? taxon_name.ref.display_name : "")
    end
    s.strip.html_safe
  end

  def self.create_new(params)
    return false if (params[:specimen_id].blank? || (params[:taxon_name].blank? && params[:type_type].blank? && params[:otu_id].blank? && params[:notes].blank?))
    s = TypeSpecimen.new(params)
    s.save
    s
  end

end

