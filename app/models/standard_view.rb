# == Schema Information
# Schema version: 20090930163041
#
# Table name: standard_views
#
#  id            :integer(4)      not null, primary key
#  name          :string(64)
#  part_id       :integer(4)      not null DEPRECATED
#  image_view_id :integer(4)      not null
#  stage         :string(32)
#  sex           :string(32)
#  notes         :text
#  proj_id       :integer(4)      not null
#  updated_on    :timestamp       not null
#  created_on    :timestamp       not null
#  creator_id    :integer(4)      not null
#  updator_id    :integer(4)      not null
#  identifier    :string(255)   # deprecated
#  namespace_id  :integer(4)    # deprecated
#

class StandardView < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::DefaultNamedScopes 

  has_and_belongs_to_many :standard_view_groups
  
  belongs_to :image_view

  has_many :continuous_characters, :class_name => 'Chr'

  # untested
  # has_many :image_descriptions, :finder_sql => proc { "SELECT id.* FROM image_descriptions id JOIN labels l ON l.id = id.label_id
  #             JOIN sensus s ON l.label_id = s.label_id
  #             JOIN ontology_classes oc ON oc.id = s.ontology_class_id
  #             WHERE oc.id = #{ontology_class_id} AND id.image_view_id = #{image_view_id};"}

  validates_uniqueness_of :name, :scope => 'proj_id'
  validates_presence_of  :name

  validate  :check_record
  def check_record
    if sex.blank? && image_view_id.blank? && ontology_class_xref.blank? 
      errors.add(:name, 'You must either give this view a name, or tie it to an ontology class')
    end
  end

  def display_name(options = {}) # :yields: String
    name
  end

  def ontology_class # :yields: mx OntologyClass | nil
    return nil if ontology_class_xref.blank?
    OntologyClass.find(:first, :conditions => {:proj_id => Proj.find(proj_id).ontology_id_to_use, :xref => ontology_class_xref}) 
  end

  def image_description_sql # :yields: String  (where conditions for the four options)
    [:ontology_class_xref, :image_view_id, :sex, :stage].map{|v| self.send(v).blank? ? nil : "(image_descriptions.#{v.to_s} = '#{self.send(v)}')" }.compact.join(" and ")
  end

  def image_descriptions # :yields:  return all the images for a given standard view
    return ImageDescription.find(:all, :conditions => image_description_sql) # shouldn't be a problem with Proj because parts belong to them
  end

  def image_descriptions_by_otu_id(otu_id)
    scope = ImageDescription.scoped({})
    scope = scope.conditions  image_description_sql 
    scope = scope.conditions "image_descriptions.otu_id = ?", otu_id 
    scope
  end

    def self.find_for_auto_complete(params)
    tag_id_str = params[:tag_id]
    return [] if tag_id_str == nil

    value = params[tag_id_str.to_sym].split.join('%') # hmm... perhaps should make this order-independent

    lim = case params[tag_id_str.to_sym].length
          when 1..2 then  10
          when 3..4 then  25
          else lim = false # no limits
          end 

    StandardView.find(:all, :conditions => ["(standard_views.name LIKE ? OR standard_views.id = ?) AND standard_views.proj_id=?", "%#{value}%",  value.gsub(/\%/, ""), params[:proj_id]], :order => "standard_views.name", :limit => lim)
  end


end
