class Label < ActiveRecord::Base
  # Labels are names for OntologyClasses, their instantiation implies their association with at least one instance of a "real life" OntologyClass whether or not that association has be captured in the database
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::DefaultNamedScopes

  # IMPORTANT: callbacks must come before the has_many :dependent => :nullify statements 
  before_validation :validate_plurals_are_not_further_pluralized
  before_destroy :validate_label_not_used_with_xrefed_ontology_class_as_obo_id
  before_update :validate_label_spelling_is_not_changed_when_used_as_obo_label

  validates_presence_of :name

  # TODO: revisit, no non-latin characters? 
  # validates_format_of :name, :with => /\A\w+(\Z|.*\w+\Z)/i, :message => 'invalid label, you may need to trim space or you have non-alphabetical characters'
  validates_uniqueness_of :name, :scope => :proj_id, :message => 'that label is already present in this project'
  validates_length_of :active_msg, :within => 5..144, :allow_nil => true

  belongs_to :language
  belongs_to :plural_of_label, :foreign_key => 'plural_of_label_id', :class_name => "Label" # TODO: rename to singular_of
  belongs_to :activator, :foreign_key => 'active_person_id', :class_name => "Person"
  has_one :plural_form, :foreign_key => 'plural_of_label_id', :class_name => "Label", :dependent => :nullify

  has_many :sensus, :dependent => :destroy
  has_many :ontology_classes, :through => :sensus, :uniq => true # directly tied, plural ties are not included here
  has_many :ontology_classes_as_plural, :through => :sensus, :primary_key => 'plural_of_label_id' # #TEST directly tied, plural ties are not included here
  has_many :ontology_classes_in_OBO, :foreign_key => 'obo_label_id', :class_name => 'OntologyClass', :dependent => :nullify
  has_many :labels_refs, :dependent => :destroy 

  # has_many :tags_with_count, :source => :tag, :through => :taggings, 
  #   :group => "tags.id", :joins => :taggings,
  #   :select = "tags.*, COUNT('taggings.id') AS frequency"

  scope :singular, :conditions => 'plural_of_label_id is null'
  scope :with_definitions, :conditions => "labels.id IN (SELECT label_id FROM sensus)"  # alias for with_ontology_classes
  scope :without_ontology_classes, :conditions => "labels.id NOT IN (SELECT label_id FROM sensus)" 
  scope :all_for_ontology_class, lambda {|*args| {:conditions => ["(labels.id in (select s.label_id from sensus s where s.ontology_class_id = ?)) OR (labels.id in (select lp.id from labels lp where lp.plural_of_label_id in (select s.label_id from sensus s where s.ontology_class_id = ?))) ", args.first || -1, args.first || -1]}}
  scope :all_singular_tied_to_ontology_classes, lambda {|*args| {:conditions => "(labels.id in (select s.label_id from sensus s))"}} 

  scope :ordered_by_label_length, :order => 'length(labels.name)'
  scope :ordered_by_active_on, :order => 'labels.active_on DESC', :conditions => 'labels.active_on IS NOT NULL'

  # pass an Array of strings, escape results *before* you use with_label_from_array 
  scope :with_label_from_array, lambda {|*args| {:conditions => (args.first.size > 0 ? "(" + args.first.collect{|a| "(labels.name = \"#{a.gsub(/\"/, "\"")}\")"}.join(" OR ") + ")" : "labels.name = '-1'") }}

  scope :that_are_homonyms, {
    :group => "sensus.label_id",
    :joins => 'JOIN sensus on labels.id = sensus.label_id',
    :having => 'count(distinct sensus.ontology_class_id) > 1' 
  }

  # TODO: optimize
  scope :that_are_synonyms, :conditions => 'id in (select distinct label_id from sensus s where s.ontology_class_id in
      (select ontology_class_id from (
          select ontology_class_id, count(distinct label_id) c from sensus group by ontology_class_id 
      ) t1 where t1.c > 1))'

  scope :with_first_letter, lambda {|*args| { :conditions => ["name LIKE ?", (args.first ? "#{args.first}%" : -1)]}} 
  scope :without_plural_forms, :conditions => 'id NOT IN (SELECT plural_of_label_id id FROM labels where plural_of_label_id IS NOT NULL)'

  # "energize" callbacks can't be private
  before_create :energize_create_label
  before_update :energize_update_label
  def energize_create_label
    self.energize(creator_id, "created the label")
    true 
  end

  def energize_update_label
    if self.name_changed?
      self.energize(updator_id, "changed the spelling of the label")
    end
    true
  end

  def display_name(options = {})
    opt = {
      :type => nil # :list, :head, :select, :selected, :sub_select, :material_examined_verbose
    }.merge!(options.symbolize_keys)
    case opt[:type]
    when[:select]
      name
    else
      name
    end
  end

  def is_homonym?
    self.ontology_classes.size > 1
  end

  def is_synonym?
    self.ontology_classes.each do |oc|
      return true if oc.labels.size > 0
    end
  end

  def has_plural?
    !self.plural_form.blank?
  end

  def is_plural?
    !self.plural_of_label.blank?
  end

  # aliased
  def has_ontology_class?
    has_defintion?
  end

  def has_ontology_class_with_xref?
    self.ontology_classes.with_populated_xref.size > 0 
  end

  def has_definition?
    self.sensus.size > 0
  end

  # returns an Array of Strings
  def all_forms
    plural_form.blank? ? [name] : [plural_form.name, name].sort
  end

  # returns a Hash of {Label => [OntologyClass1...OntologyClassn]} where 
  # OntologyClass has Label.name in definition AND Label.ontology_classes.size == 0
  def self.without_ontology_classes_but_used_in_ontology_class_definitions(params)
    opts = {:proj_id => nil}.merge!(params) 
    if proj = Proj.find(opts[:proj_id])
      labels = {} 
      proj.labels.without_ontology_classes.each do |l|
        ocs = proj.ontology_classes.with_definition_containing(l.name)
        labels.merge!(l => ocs) if ocs.size > 0
      end
    else 
      return {} 
    end
    return labels 
  end 

  def synonyms_by_ontology_class(ontology_class)
    Sensu.by_ontology_class(ontology_class).excluding_label(self).collect{|s| s.label}.uniq.sort{|a,b| a.name <=> b.name}
  end

  def self.auto_complete_search_result(params = {})
    tag_id_str = params[:tag_id]
    return false if (tag_id_str == nil  || params[:proj_id].blank?)

    value = params[tag_id_str.to_sym].split.join('%')

    lim = case params[tag_id_str.to_sym].length
          when 1..2 then 3 
          when 3..4 then 5 
          else lim = false # no limits
          end 
    Label.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id = ?", "%#{value}%", value.gsub(/\%/, ""), params[:proj_id]], :order => "length(name)", :limit => lim ).uniq
  end

  def self.search_redirect(params = {})
    {:controller => params[:hidden_field_class_name].downcase.to_sym, :id => params[:onto_search][:search_id], :action => :show}
  end

  # scales from 0-9
  def active_index
    case ((Time.now.to_i - self.active_on.to_i).to_f / 3600).to_i
    when 0..23
      factor = 3
    when 24..167
      factor = 2
    when 168..720
      factor = 1
    else
      factor = 0
    end

    # TODO: heat factor increase with recentness (hrs, days, weeks, months) => [3,2,1,0]
    case active_level + factor - 1
    when 0..10
      active_level + factor - 1
    when 10..1000000
      10 
    else
      nil 
    end
  end

  def energize(person_id, msg)
    self.active_person_id = person_id
    self.active_msg = msg
    self.active_level += 1
    self.active_on = Time.now()
  end

  def as_json
    h = Hash.new
    h[name] = {}
    sensus.each do |s|
      if !s.ontology_class.xref.nil?
        h[name].merge!(Ontology::OntologyMethods.obo_uri(s.ontology_class) => s.ref.display_name)
      end
    end
    h
  end

  protected

  def validate_label_spelling_is_not_changed_when_used_as_obo_label
    if self.name_changed? && self.ontology_classes_in_OBO.size > 0
      errors.add(:name, "This label is used for as an OBO label. It can not be changed.")
      false
    end
  end

  def validate_plurals_are_not_further_pluralized 
    if !plural_of_label_id.blank? && Label.find_by_plural_of_label_id(plural_of_label_id)
      errors.add(:plural_of_label_id, "The root of this label is already pluralized.")
      false
    end
  end

  def validate_label_not_used_with_xrefed_ontology_class_as_obo_id
    if self.ontology_classes_in_OBO.with_populated_xref.size > 0
      errors.add(:name, "This label is used for a xrefed class or as an OBO label. It can not be destroyed.")
      return false
    end
    true
  end

end
