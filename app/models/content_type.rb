# == Schema Information
# Schema version: 20090930163041
#
# Table name: content_types
#
#  id         :integer(4)      not null, primary key
#  sti_type   :string(255)
#  is_public  :boolean(1)
#  name       :string(255)
#  can_markup :boolean(1)      default(TRUE)
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#
# TODO: REGENERATE ABOVE

class ContentType < ActiveRecord::Base
  has_standard_fields  
  
  self.inheritance_column = 'sti_type'

   # If you create a new subclass you must include the CamelCase sti_name
  # you need ContentType:: prefix to create new.
  # Model must end in 'Content'.  Model filename must end in _content (matching model name).
  BUILT_IN_TYPES = [
      'ContentType::GmapContent',                           # A google maps map.
      'ContentType::SpecimensContent',                      # A simple Specimen table, with KML links
      'ContentType::MaterialExaminedContent',               # A publication ME section
      'ContentType::TaxonNameHeaderContent',
      'ContentType::PublicImagesContent',
      'ContentType::TaxonomicNameSynonymsContent',
      'ContentType::ReferencedDistributionContent',
      'ContentType::ReferencedDistributionNativeContent',
      'ContentType::TaxonomicHistoryContent',
      'ContentType::TagsOnOtuByKeywordContent',
      'ContentType::TaxonNameDeprecatedTypeInfoContent',    # THIS IS ONLY FOR EXISTING DATA THAT NEEDS TO STAY LIVE
      'ContentType::HislHosts'                              # (see above)
    ]

  ALL_TYPES = BUILT_IN_TYPES + ['ContentType::TextContent']

  # def self.all_types
  #  self.custom_types << 'TextContent'
  # end


  has_many :content_templates, :through => :content_templates_content_types
  has_many :content_templates_content_types, :dependent => :destroy
  has_many :contents
  has_many :mapped_chr_groups, :class_name => "ChrGroup", :dependent => :nullify 
  has_many :otus, :through => :contents

  scope :with_content, :conditions => "content_types.id IN (SELECT DISTINCT content_type_id from contents)"
  scope :with_chr_group_mapping, :conditions => "content_types.id IN (SELECT DISTINCT content_type_id from chr_groups WHERE chr_groups.content_type_id IS NOT NULL)"

  # before_validation_on_create :set_defaults_if_needed
  before_validation(:on => :create) do
    set_defaults_if_needed
  end

  validate do
    errors.add(:sti_type, "Invalid ContentType") if !ContentType::ALL_TYPES.include?(sti_type)
    errors.add(:name, "not provided to TextContent type") if sti_type == 'ContentType::TextContent' && name.blank?
  end

  validate(:on => :create) do
    errors.add(:sti_type, "mx ContentType already included in this project") if ContentType.find(:first, :conditions => {:proj_id => proj_id, :sti_type => sti_type, :name => nil})
  end

  def display_name(options = {})
    if !doc_name.blank?
      doc_name
    else
      !name.blank? ? name : "NOTIFY ADMIN: missing #display_name for built in content type subclass"
    end
  end

  def display_subject
    self.built_in_subject ? built_in_subject : "#{subject}"
  end

  def built_in_subject
    false 
  end

  # default for subclasses
  def public_partial
    self.partial
  end

  # provide for ContentType subclasses 
  def description
    ''
  end

  # returns a class reference to a ContentType subclass
  # def constantized
  ##  if !self.sti_type == "TextContent"
   # "ContentType::#{sti_type}".constantize
   # else
   #   ContentType
   # end
  # end

  # creates the built in ContentType type if needed
  # returns the ContenType::CustomType
  # takes a string like "ContentType::CustomContent"  
  def self.create_if_needed(custom_type, proj_id)
    ct = custom_type
    sti_type = ct # .gsub(/ContentType::/, "")  # sti type excluded the superclass
    if t = ContentType.find(:first, :conditions => {:proj_id => proj_id, :sti_type => sti_type})
      return t
    else
      ct.constantize.create! 
    end
  end

  # def tp_xml(options ={})
  #  opt = {:target => ''}.merge!(options)
  #  doc = Builder::XmlMarkup.new(opt)
  #  doc.foo(self.name)
  #  # do stuff!
  #  return opt[:target]
  # end

  ## Rendering options, see subclassess for overrides 

  # Include this content type in text dumps?
  # Always true for TextContent classes.
  def renders_as_text?
   self.class == TextContent ? true : false 
  end

  # Style inline in text dump?
  def render_as_subheading?
    self.render_as_subheading
  end

  def render_header?
    true
  end

  protected
  
  def set_defaults_if_needed
    self.sti_type = "ContentType::TextContent" if self.sti_type.blank?
    self.is_public = true if !self.sti_type.blank? # custom content types are public by default (for now)
  end


end

## Subclasses

# the text subclass, the name is user defined

class ContentType::TextContent < ContentType

  validates_presence_of :name

  def partial
    # :object => Content
    '/content/c'
  end

  def public_partial
    self.partial
  end
  
  def self.description
    'A content type holding a block of text. Type defined by the user.'
  end

  # a list of all the Chrs linked through chr groups, perhaps should be moved to Text subclass as it doesn't make sense for all others
  def chrs 
    self.mapped_chr_groups.inject([]) {|sum, cg| sum << cg.chrs}.flatten # not unique, chrs can be in multiple chr groups
  end

  # pass an Otu, get the codings, in order back, if no coding nil is returned
  # returns an array of [[Chr, [Codings]], ... ]
  def codings_by_otu(otu)
    self.chrs.inject([]) {|sum, c| sum << [ c, Coding.by_otu(otu).by_chr(c)]}
  end

  def natural_language_by_otu(otu)
    return false if !otu.class == Otu
    desc = []
    
    self.codings_by_otu(otu).each do |c|
      t = ''
      t << c[0].display_name
      t << ': '
      if c[1].size == 0
        t << 'NOT CODED'
      else
        t << c[1].collect{|coding| coding.chr_state_name}.join("; ")
      end
      desc << t
    end
    desc.join(". ") + '.'
  end

end

# see content_types in model folder for subtypes
# the #partial method in those models needs to only have an @otu = Otu
# IMPORTANT: If you add a class there you must update the self.custom_types array
