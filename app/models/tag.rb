# == Schema Information
# Schema version: 20090930163041
#
# Table name: tags
#
#  id                :integer(4)      not null, primary key
#  keyword_id        :integer(4)
#  addressable_id    :integer(4)
#  addressable_type  :string(64)
#  notes             :text
#  ref_id            :integer(4)
#  pages             :string(255)
#  pg_start          :string(8)
#  pg_end            :string(8)
#  proj_id           :integer(4)      not null
#  creator_id        :integer(4)      not null
#  updator_id        :integer(4)      not null
#  updated_on        :timestamp       not null
#  created_on        :timestamp       not null
#  referenced_object :string(255)
#

class Tag < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::DefaultNamedScopes

  belongs_to :addressable, :polymorphic => true
  belongs_to :ref, :include => :authors
  belongs_to :keyword
  has_many :metatags, :as => :addressable, :dependent => :destroy, :include => [:keyword, :ref], :order => 'refs.cached_display_name ASC', :class_name => 'Tag' 

  scope :by_class, lambda {|*args| {:conditions => ["tags.addressable_type = ?", (args.first || -1)] }}
  scope :by_keyword, lambda {|*args| {:conditions => ["tags.keyword_id = ?", (args.first || -1)] }}
  scope :with_xref_keywords, :conditions => 'tags.keyword_id IN (SELECT id FROM keywords WHERE is_xref = 1)'
  scope :with_addressable_id, lambda {|*args| {:conditions => ["tags.addressable_id = ?", (args.first || -1)] }}
  scope :with_referenced_object_set, :conditions => ['referenced_object IS NOT null AND referenced_object != ""']
  scope :with_referenced_object, lambda {|*args| {:conditions => ["referenced_object = ?", (args.first ? "#{args.first}" : -1)] }}
  scope :with_notes_starting_with, lambda {|*args| {:conditions => ["tags.notes like ?", (args.first ? "#{args.first}%" : -1)] }}
  scope :with_notes_not_starting_with, lambda {|*args| {:conditions => ["tags.notes not like  ?", (args.first ? "#{args.first}%" : -1)] }}
  scope :with_referenced_object_starting_with, lambda {|*args| {:conditions => ["tags.referenced_object like ?", (args.first ? "#{args.first}%" : -1)] }}
  scope :with_referenced_object_not_starting_with, lambda {|*args| {:conditions => ["tags.referenced_object not like  ?", (args.first ? "#{args.first}%" : -1)] }}

  validates_presence_of :keyword_id
  validates_presence_of :addressable_id
  validates_presence_of :addressable_type
  validates_format_of :referenced_object, :with => /:*\w+:\d+\Z/, :allow_nil => true, :if => '!self.referenced_object.blank?', :message => 'referenced object has an invalid format'
validate :check_record
  def check_record
    o = self.referenced_object_object
    if o == false
      errors.add(:referenced_object, "can't return the object referenced")
    end
    if o == self.tagged_obj
      errors.add(:referenced_object, "can't reference self")
    end
  end

  before_save :clean_notes
  def clean_notes
    notes && notes.gsub!(/\n/,"")
  end

  # the active properties cluster
  after_create :energize_create_tag
  def energize_create_tag
    case addressable_type
    when 'OntologyClass'
      tagged_obj.labels.each do |l|
        l.energize(creator_id, "added the tag \"#{self.keyword.keyword}\" to a class labeled with")
        l.save!
      end 
    when 'Label' 
      l = tagged_obj 
      l.energize(creator_id, "added the tag \"#{self.keyword.keyword}\" to the label")
      l.save! 
    end
    true
  end

  after_destroy :energize_destroy_tag
  def energize_destroy_tag(person_id = $person_id)
    case addressable_type
    when 'OntologyClass'
      tagged_obj.labels.each do |l|
        l.energize(person_id, "destroyed a tag \"#{self.keyword.keyword}\" on a class labeled with")
        l.save!
      end 
    when 'Label' 
      l = tagged_obj 
      l.energize(person_id, "destroyed a tag \"#{self.keyword.keyword}\" on a class labeled with")
      l.save! 
    end
    true
  end
  
  # display the Tag
  def display_name(options = {})
     opt = {
      :type => :line, # :list, :without_keywords
      :close => true}.merge!(options.symbolize_keys)
    s = ''
    case opt[:type]
      when :list
        s << "#{self.keyword.display_name} / #{self.tagged_obj.display_name}"
      when :without_keywords
        s << "<div id=\"t_#{id}\" style=\" padding: .2em;\">"
        s << '<span class="lbl4">' + self.ref.authors_year.strip + '</span>' if self.ref
        s << ('<span style="font-size: 10pt; text-align:right;veritcal-align:top; color:#666"> ' + self.notes + '</span>') unless self.notes.blank?
        s << '&nbsp; <span class="small_grey">by:' + creator.full_name + '</span>' 
      else
        s << "<div id=\"t_#{id}\" style =\"display: inline;\">"
        s << "<span class=\"lbl4\">#{self.keyword.display_name}</span>" 
        s << " (from: " + self.ref.authors_year.strip + ")" if self.ref
        s << ('<span style="font-size: 10pt; text-align:right;veritcal-align:top; color:#666"> ' + self.notes + '</span>') if self.notes
        s << '&nbsp; <span class="small_grey">by:' + creator.full_name + '</span>'
      end
      s << '</div>' if opt[:close] # somewhat silly
    s
  end 

  # requires :obj => ObjectToTag, :keyword => Keyword
  # optional: Tag#methods
  # note that the root TaxonName can be added but needs to be saved (again) if this is used to create. 
  def self.create_new(options = {}) # :yields: Tag
    opt = {
      :addressable_id => options[:obj].id,
      :addressable_type => options[:obj].class.to_s
    }.merge!(options).to_options!
    opt.delete(:obj)
    t = Tag.new(opt)
    t.save 
    t 
  end  

  # returns an Array of Tags that use the Array of :keywords 
  def self.by_keywords(options = {})
    @opt = {
      :keywords => [],
    }.merge!(options.symbolize_keys)
    @opt[:keywords].inject([]){|sum, k| sum += Tag.find(:all).by_keyword(k)}.flatten
  end
 
  # returns the object that the tag is attached to
  # wrapped in a begin in case records are somehow broken (they shouldn't be)
  def tagged_obj
    begin
      if ActiveRecord::const_get(self.addressable_type).respond_to?(:proj_id)
        ActiveRecord::const_get(self.addressable_type).find(self.addressable_id, :conditions => ["proj_id = ?", self.proj_id])
      else
        ActiveRecord::const_get(self.addressable_type).find(self.addressable_id)
      end
    rescue ActiveRecord::RecordNotFound
      false
    end
  end

  # referenced_object can contain a single reference to another namespaced object in the form
  # namespace:id
  # Where the id always follows the rightmost :
  # If additional : are present
  #  :<mx class>:id   - if referenced_object starts with a : it's assumed to be mx scoped (the present database), so :label:12 == Label.find(12)
  # There is one additional special namespace for a given project, the ontology namespace, which can be used to pseudo foreign key reference OntologyClass.xref
  #  Proj#ontology_namespace:id 
  # Additional objects (external) can be cased out and returned below 

  def referenced_object_object
    return nil if self.referenced_object.blank?
    v = self.referenced_object.split(":")
    return false if v.size == 1
    begin
      case v[0]
      when "" # hits like :OntologyClass:123
        ActiveRecord::const_get(v[1].downcase.camelcase).find(v[2])
      when Proj.find(self.proj_id).ontology_namespace
        o = OntologyClass.find(:first, :conditions => {:xref => "#{v[0]}:#{v[1]}"})
        return false if !o
        o
      else # hit this if we have any other string with a ":" in it, for instance cross references to other dbs (e.g. FbT:1234)
        return self.referenced_object
      end
    rescue
      # should likely raise here
       false
    end
  end

  def referenced_object_id
    self.referenced_object.split(":").last
  end

  # why do we need this? TODO: deprecate?
  # if this tag is on a OntologyClass, find that OntologyClass, and take it's xref to update the referenced object
  def update_to_ontology_namespace
    o = self.referenced_object_object
    return false if !o.class == OntologyClass 
    self.referenced_object = o.xref if o && (o.class == OntologyClass) && !o.xref.blank?
    self.save
  end

  # TODO: where is this used?
  # implement the comparison operator so we can sort tags, etc.
  def <=>(x)
    if self.ref and x.ref
      self.ref.display_name <=> x.ref.display_name
    else
      +1
    end
  end

  # render the pg text
  def page_txt
    s = ''
    s << self.pg_start if !pg_start.blank?
    s << '-' + self.pg_end if !pg_end.blank?
    s << ", " + self.pages if !pages.blank?
    s
  end
   
end
