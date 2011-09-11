require 'ontology/visualize/newick'
require 'ontology/visualize/svg'

class OntologyClass < ActiveRecord::Base
  # is_obsolete classes in OBO have NO relationships but relationships can be maintained for obsolete terms (they are excluded programatically from the OBO dump in mx)

  # IMPORTANT in_place_editing has been hacked to handle versioned (when this is gemified it will have to be updated)
  versioned

  set_table_name "ontology_classes"
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  serialize :illustration_IP_votes, Array # not implemented

  belongs_to :written_by, :foreign_key => 'written_by_ref_id', :class_name => 'Ref'
  belongs_to :obo_label,  :foreign_key => 'obo_label_id', :class_name => 'Label'
  belongs_to :taxon_name, :foreign_key => 'highest_applicable_taxon_name_id', :class_name => 'TaxonName'

  # primary_relationship object_relationship secondary_relationship, e.g. antennae (primary) part_of head (secondary)
  has_many :primary_relationships, :class_name => 'OntologyRelationship', :foreign_key => 'ontology_class1_id', :dependent => :destroy   # children
  has_many :secondary_relationships, :class_name => 'OntologyRelationship', :foreign_key => 'ontology_class2_id', :dependent => :destroy # parents

  # these next 3 return all related classes, regardless of object_relationship type
  has_many :immediately_related_ontology_classes, 
      :class_name => "OntologyClass",
      :finder_sql => 'SELECT DISTINCT oc.* FROM ontology_classes oc 
                      LEFT JOIN ontology_relationships or1 ON oc.id = or1.ontology_class1_id
                      LEFT JOIN ontology_relationships or2 ON oc.id = or2.ontology_class2_id
                      WHERE or1.ontology_class2_id = #{id} OR or2.ontology_class1_id = #{id};'
  
  has_many :child_ontology_classes, :through => :secondary_relationships, :source => :ontology_class1 
  has_many :parent_ontology_classes, :through => :primary_relationships, :source => :ontology_class2 

  has_many :sensus, :dependent => :destroy, :order => 'sensus.position'
  has_many :labels, :through => :sensus, :uniq => true # singular only now, these are homonyms 
  has_many :all_labels_through_sensus, :through => :sensus, :source => :label  

  #  has_one :preferred_label, :through => :sensus, :source => :label, :order => 'sensus.position', :limit => 1

  # pass a String or Array of Strings, filters by singular or plural forms of Labels matching arguments
  scope :by_label_including_plurals, lambda {|*args| {
    :conditions => "ontology_classes.id IN (select id from 
    ((SELECT ontology_class_id id from sensus s  JOIN labels l ON s.label_id = l.id WHERE #{SqlHelper::where_scope_for_name(:l, *args)} )
    UNION (SELECT ontology_class_id id from sensus s2 JOIN labels l1 ON s2.label_id = l1.id JOIN labels lj on l1.id = lj.plural_of_label_id WHERE #{SqlHelper::where_scope_for_name(:lj, *args)})) alias_b)"} 
  }

  # TODO: ordered_by_label_name needs re-visiting, this isn't right
  scope :ordered_by_label_name, :order => 'sensus.position, labels.name', :include => [:labels, :sensus]
  scope :ordered_by_xref, :order => 'xref'

  # scope conditions need to be re-written
  #  scope :with_definition_containing, lambda {|*args| {:conditions => ["definition REGEXP ?",  (args.first ?  "[[:<:]]#{args.first}[[:>:]]" : -1)]}}

  def self.with_definition_containing(string)
    string ||= -1
    where('definition REGEXP ?', "[[:<:]]#{string}[[:>:]]")
  end

  scope :with_populated_xref, :conditions => "xref IS NOT NULL AND xref != ''"
  scope :with_xref_namespace, lambda {|*args| {:conditions => ["xref LIKE ?", args.first + ":%"]}} # :order => 'xref', 
  scope :with_figures, lambda {|*args| {:conditions => "ontology_classes.id IN (SELECT addressable_id from figures WHERE addressable_type = 'OntologyClass')"}} 
  scope :with_obo_label, :conditions => 'obo_label_id IS NOT NULL and obo_label_id != ""'

  # Without
  scope :without_xref, :conditions => 'xref IS NULL OR xref = ""' 
  scope :without_ontology_relationships, lambda {|*args| {:conditions => "ontology_classes.id NOT IN (SELECT DISTINCT ontology_class1_id from ontology_relationships) AND ontology_classes.id NOT IN (SELECT ontology_class2_id from ontology_relationships)" }} 
  scope :without_sensus, lambda {|*args| {:conditions => "ontology_classes.id NOT IN (SELECT DISTINCT ontology_class_id from sensus)"}} 
  scope :without_figures, lambda {|*args| {:conditions => "ontology_classes.id NOT IN (SELECT DISTINCT addressable_id from figures WHERE addressable_type = 'OntologyClass')"}} 
  scope :without_figure_markers, lambda {|*args| {:conditions => "ontology_classes.id NOT IN (SELECT DISTINCT addressable_id FROM figures WHERE (addressable_type = 'OntologyClass') AND figures.id IN (SELECT DISTINCT figure_id FROM figure_markers)   )"}} 
  scope :without_child_relationship, lambda {|*args| {:group => 'ontology_classes.id', :conditions => ["ontology_classes.id NOT IN (SELECT ontology_class2_id from ontology_relationships WHERE object_relationship_id = ?)", (args.first ?  args.first : -1)] }} 
  
  scope :include_tags, :include => [:tags]
  scope :that_are_obsolete, :conditions => "is_obsolete = 1"
  scope :that_are_not_obsolete, :conditions => "is_obsolete != 1"

  validates_presence_of :definition
  validates_presence_of :written_by 
  validates_uniqueness_of :definition, :scope => :proj_id, :allow_blank => false, :allow_nil => false, :message => "That defintion already exists in this ontology."
  validates_uniqueness_of :xref, :message => 'xref alredy exists, pick a new one', :allow_blank => true, :allow_nil => true, :scope => "proj_id" 
  validates_format_of :xref, :with => /\A\w+\:\d+\Z/i, :message => 'must be in the format "foo:123"', :if => Proc.new{|o| !o.xref.blank?} 

  before_update :energize_update_class
  after_destroy :energize_destroy_class

  def energize_update_class
    labels.each do |l|
      l.energize(updator_id, 'updated a class labeled with')
      l.save!
    end
    true
  end

  def energize_destroy_class(person_id = $person_id)
    labels.each do |l|
      l.energize(person_id, 'destroyed a class labeled with')
        l.save!
      end 
    true
  end

  # Two sets of fields are coupled
  # If you want a xref you must fill in OBO label.
  # If you want to obsolete you must provide a reason.
  validate :check_record
  def check_record
    definition.strip! if !definition.nil?
    errors.add(:definition, "invalid format for definition") if definition =~ /\A\s/i  
    errors.add(:definition, "contains linebreaks") if (definition =~ /\r\n/) || (definition =~ /\r/) || (definition =~ /\n/)

    # NOTE could just build one field logic (reason = true), but we want caution when obsoleting, so extra step OK.
    if is_obsolete && is_obsolete_reason.blank?
      errors.add(:is_obsolete_reason, "You must provide a reason for obsoleting this class.")
    end
    if !is_obsolete && !is_obsolete_reason.blank?
      errors.add(:is_obsolete, "You provided a reason for obsoletion, you must also check the box.")
    end

    if !xref.blank? && obo_label_id.blank?
      errors.add(:obo_label_id, "You must select a OBO label before generating a xref for a class.")
    end

  end

  # TODO: is this safe? does written_by really equate to sensu?! (probably not)
  after_save :ensure_that_labels_contains_obo_label

  before_save :set_illustration_ip_votes
  def set_illustration_ip_votes
    self.illustration_IP_votes = [] if self.illustration_IP_votes == nil
  end

  before_destroy :check_for_xref
  def check_for_xref
    if !self.xref.blank?
        errors.add(:xref, "You can't destroy a class that has an existing xref in this manner.")
      false
    end
  end

  # TODO: Roles deprecation
  def created_or_admin(person) # :yields: Boolean
    if person.id.to_i == self.creator_id.to_i || person.is_admin || person.is_ontology_admin
      true
    else
      false
    end
  end

  def display_name(options = {}) # :yields: String
    opt = {:type => :inline 
    }.merge!(options.symbolize_keys)
    case opt[:type]
    when :for_select_list
      "#{self.definition} <span style='padding:1px;background-color:#b5ebc7;'>#{self.label_name(:type => :preferred)}</span>"
    when :label_first
      "<span style='padding:1px;background-color:#b5ebc7;'>#{self.label_name(:type => :preferred)}</span> #{self.definition}"
    when :label_first_select
      "#{self.label_name(:type => :preferred)} -- #{self.definition}"
    when :figure
      "#{self.definition} <span style='padding:1px;background-color:#b5ebc7;'>#{self.label_name(:type => :preferred)}</span>"
    when :inline
      definition 
    else
      definition 
    end  
  end

  def label_name(options = {}) # :yields: String
    opt = {
      :type => :preferred 
    }.merge!(options.symbolize_keys)
    if self.labels.size > 0 || !self.obo_label
      case opt[:type]
      when :top_sensu
        self.sensus.ordered_by_position.including_label.first.label.name
      when :oldest
        self.sensus.ordered_by_age.including_label.first.label.name
      when :preferred
        sensuz = self.sensus.including_label.ordered_by_position
        if sensuz.size > 0
          sensuz.first.label.name
        elsif self.obo_label
          self.obo_label.name
        else
          'NO LABEL PROVIDED'
        end
      end
    else
      'NO LABEL PROVIDED'
    end
  end

  # TODO: refactor to a single SQL in Label?
  def all_labels # :yields: Array of Strings
    # includes plurals etc. 
    self.labels.inject([]){|sum, l| sum + l.all_forms}.sort
  end

  def hash_labels # :yields: {Label => [id_string, id_string ... id_string]
    # See Linker.rb 
    all_labels.inject({}){|h, l| h.merge(l => [self.id])}
  end

  # ? TODO: make this a has_one with finder?
  def preferred_label # :yields: Label or Label.new
    ss = self.sensus.ordered_by_position.first
    ss ? ss.label : Label.new 
  end

  def relationships
    OntologyRelationship.with_ontology_class(id)
  end

  def self.by_label_including_count(proj_id)
    OntologyClass.find_by_sql(["SELECT oc.*, count(distinct s.label_id) as total_labels from ontology_classes oc join sensus s on oc.id = s.ontology_class_id WHERE oc.proj_id = ? GROUP BY s.ontology_class_id ORDER BY total_labels DESC;", proj_id]) 
  end

  def xrefs_from_tags # :yields: Array of Strings
  # items are are 'Foo:1234' style references derived from Tags that use is_xref Keywords
    xrefs = [] 
    xrefs += self.tags.with_xref_keywords.collect{|x| !x.referenced_object.blank? ? x.referenced_object : nil}
    xrefs.compact.uniq
  end

  # # TODO: rename to clarify, this is all relationships in which self is present
  # def children
  #   OntologyRelationship.find(:all, :conditions => "((ontology_class1_id = #{self.id}) OR (ontology_class2_id = #{self.id}))", :include => [:ontology_class2]).collect{|o| o.ontology_class2}
  # end

  # The is_a, part_of methods here are for convienience. They not optimized to repeated calls since they have to find the required relationship(s).

  def is_a_children        # :yields: Array of immediate is_a related OntologyClasses
    self.child_ontology_relationships(:relationship_type => ObjectRelationship.find_by_interaction_and_proj_id('is_a', self.proj_id).id).collect{|o| o.ontology_class1}
  end

  def is_a_parents         # :yields: Array of immediate is_a related OntologyClasses
    self.related_ontology_relationships(:relationship_type => [ObjectRelationship.find_by_interaction_and_proj_id('is_a', self.proj_id).id], :max_depth => 1, :direction => :parents).collect{|o| o.ontology_class2}
  end                      

  def is_a_descendants     # :yields: Array of all is_a related OntologyClasses
    self.related_ontology_relationships(:relationship_type => [ObjectRelationship.find_by_interaction_and_proj_id('is_a', self.proj_id).id], :max_depth => 20000, :direction => :children).collect{|o| o.ontology_class1}
  end                      

  def is_a_ancestors       # :yields: Array of all is_a related OntologyClasses
    self.related_ontology_relationships(:relationship_type => [ObjectRelationship.find_by_interaction_and_proj_id('is_a', self.proj_id).id], :max_depth => 20000, :direction => :parents).collect{|o| o.ontology_class2}
  end                      
                          
  def part_of_ancestors    # :yields: Array of all the OntologyClasses this instance is part of (additionally logically chained through is_a)
    self.logical_relatives(:direction => :parents).keys    
  end
                           
  def part_of_descendants  # :yields: Array of all the OntologyClasses this instance is part of (additionally logically chained through is_a)
    self.logical_relatives(:direction => :children).keys    
  end

  def part_of_children # :yields: Array of the immediate child part_of related OntologyClasses (additionally logically chained through is_a)
    children = [] 
    part_of_id = ObjectRelationship.find_by_interaction_and_proj_id('part_of', self.proj_id).id
    children += self.secondary_relationships.by_object_relationship(part_of_id).collect{|o| o.ontology_class1}     # get the part of children - that's easy
    self.is_a_descendants.each do |d| # get all the things that are (is_a) self 
      children += d.secondary_relationships.by_object_relationship(part_of_id).collect{|o| o.ontology_class1}          # get all their children, and only those children
    end
    children.uniq
  end                   

  def part_of_parents # :yields: Array of the immediate parent part_of related OntologyClasses (additionally logically chained through is_a)
    parents = []
    
    part_of_id = ObjectRelationship.find_by_interaction_and_proj_id('part_of', self.proj_id).andand.id
    return [] if part_of_id.nil?

    parents += self.primary_relationships.by_object_relationship(part_of_id).collect{|o| o.ontology_class2} # get the part of children - that's easy
    self.is_a_ancestors.each do |d| # get all the things that are (is_a) self 
      parents += d.primary_relationships.by_object_relationship(part_of_id).collect{|o| o.ontology_class2}  # get all their children, and only those children
    end
    parents.uniq 
  end                      

  def parents_by_relationship(relationship) # :yields: Array of the immediate parent part_of related OntologyClasses (includes those inferred through given is_a relationships)
    # pass a String
    parents = []
    if relationship = ObjectRelationship.find_by_interaction_and_proj_id(relationship, self.proj_id)
    parents += self.primary_relationships.by_object_relationship(relationship.id).collect{|o| o.ontology_class2} # get the part of children - that's easy
    self.is_a_ancestors.each do |d| # get all the things that are (is_a) self 
      parents += d.primary_relationships.by_object_relationship(relationship.id).collect{|o| o.ontology_class2}  # get all their children, and only those children
    end
    parents.uniq 
    else
      []
    end
  end

  def children_by_relationship(relationship = '') # :yields: Array of the immediate child part_of related OntologyClasses (includes those inferred through given is_a relationships)
    # pass a String
    children = [] 
    if relationship = ObjectRelationship.find_by_interaction_and_proj_id(relationship, self.proj_id)
      children += self.secondary_relationships.by_object_relationship(relationship.id).collect{|o| o.ontology_class1}  # get the part of children - that's easy
      self.is_a_descendants.each do |d| # get all the things that are (is_a) self 
        children += d.secondary_relationships.by_object_relationship(relationship.id).collect{|o| o.ontology_class1}   # get all their children, and only those children
      end
      children.uniq
    else
      []
    end
  end

  # Returns immediately attached OntologyRelationships only (does not recurse nor infer) 
  def child_ontology_relationships(options = {}) # :yields: Array of OntologyRelationships
    opt = { 
      :relationship_type => 'all'      # or a ObjectRelationships#id
    }.merge!(options.symbolize_keys)

    # TODO: modify to sort by first(top) label
    if opt[:relationship_type] == 'all'    
      OntologyRelationship.find(:all, :include => [:ontology_class1, :object_relationship, :ontology_class2], :conditions => ['ontology_class2_id = ?', self.id]) # .sort{|x,y| x.ontology_class1.preferred_label.name <=> y.ontology_class1.preferred_label.name}
    else
      OntologyRelationship.find(:all, :include => [:ontology_class1, :object_relationship, :ontology_class2], :conditions => ['ontology_class2_id = ? AND object_relationship_id = ?', self.id, opt[:relationship_type]]) # .sort{|x,y| x.ontology_class1.preferred_label.name <=> y.ontology_class1.preferred_label.name}
    end 
  end

  # A precursor example of finding all transitive relationships, in this case defaulted for is_a/part_of
  def logical_relatives(options = {}) # :yields: {OntologyClass => implied_redundant_relationships ? true : false}
    return [] if !ObjectRelationship.find_by_interaction_and_proj_id('is_a', self.proj_id) || !ObjectRelationship.find_by_interaction_and_proj_id('part_of', self.proj_id)

    rel1 = Proj.find(self.proj_id).object_relationships.by_interaction('is_a').first.id
    rel2 = Proj.find(self.proj_id).object_relationships.by_interaction('part_of').first.id
    return [] if !rel1 || !rel2 

    opt = { 
      :direction => :children,  # [:parents | :children]
      :rel1 => rel1,
      :rel2 => rel2 
    }.merge!(options.symbolize_keys)

      return nil if ![:parents, :children].include?(opt[:direction]) 

      first_result = []  # all the part_of
      second_result = [] # part_of through is_a

      result = {}

      # Find/recurse the isa/part_of tree, this gets us a unique array of pertinent OntologyRelationships
      # that reflect OntologyClass relationships that are related by one of rel1 or rel2 at each inspection. 
      rels = self.related_ontology_relationships(opt.merge(:relationship_type => [opt[:rel1], opt[:rel2]]))

      return {} if rels == nil

      # get all the part_of resuls, anything below and with a part_of, is part_of (since all others are is_a)
      to_nuke = [] # index of rels to delete before next itteration
      rels.each do |r|
        nuke = false # boolean check for delete
        if r.object_relationship_id == opt[:rel2]
          nuke = true
          if opt[:direction] == :parents
            first_result.push(r.ontology_class2) 
          else
            first_result.push(r.ontology_class1) 
          end
        end
        to_nuke.push(r) if nuke 
      end

      # !! don't do uniq on first result

      # try to invoke some loop speedup by deleting values we don't need to loop through  
      rels.delete_if{|r| to_nuke.include?(r)} 
      rels.delete_if{|r| !r.object_relationship_id == opt[:rel1]} # we only need to deal with isas of rel1 now

      # for all of the part_of results also get the is_a children (or whatever rel2 -> rel1 relationship is)

      rels.each do |rel|
        first_result.uniq.each_with_index do |r,i|
          if opt[:direction] == :parents
            second_result.insert(-1, rel.ontology_class2) if (rel.ontology_class1 == r) 
          else
            second_result.insert(-1, rel.ontology_class1) if (rel.ontology_class2 == r)
          end
        end
      end 

      second_result.uniq! # don't imply redundancies from hitting an is_a twice (is this right?! - gives "correct" result AFAIKT)

      (first_result + second_result).each do |r|
        result.merge!(r => (!result.keys.include?(r) ? false : true)) 
      end

    result
  end

  def related_ontology_relationships(options = {}) # :yields: An Array of OntologyRelationships
    # Recurses based on provided :relationship_types to return related OntologyRelationships. Does *NOT* infer.
    # return [] at depths of > 50, this could be incremented or the check changed to properly detect recursion 
   
    opt = {                             
      :relationship_type => 'all',      # 'all' or an Array of [ObjecRelationship#id, ObjecRelationship#id2 ... ]
      :max_depth => 999,                # limit to recursion
      :direction => :children,          # OR :parents
      :result => [],                    # internal 
      :depth_tracker => 0               # internal counter, do NOT initialize               
    }.merge!(options.symbolize_keys)
    os = []

    return [] if opt[:depth_tracker] > 50 # abort, there is very likely a recursion error

    if opt[:direction] == :children
      cond = 'ontology_class2_id'
    else # else find parents
      cond = 'ontology_class1_id'
    end

    if opt[:depth_tracker] < opt[:max_depth] 
      opt[:depth_tracker] = opt[:depth_tracker] + 1
      if (opt[:relationship_type].to_s == 'all')
        os = OntologyRelationship.find(:all, :include => [:ontology_class1, :object_relationship, :ontology_class2], :conditions => "#{cond} = #{self.id}")
      else
        sql = " (" + opt[:relationship_type].collect{|i| "object_relationship_id = #{i}"}.join(" OR ") + ") "
        os = OntologyRelationship.find(:all, :include => [:ontology_class1, :object_relationship, :ontology_class2], :conditions => "#{cond} = #{self.id} AND #{sql}")
      end

      opt[:result] += os
      os.each do |o|
        if opt[:direction] == :children
          opt[:result] = opt[:result] + o.ontology_class1.related_ontology_relationships(opt.merge!(:result => []))
        else
          opt[:result] = opt[:result] + o.ontology_class2.related_ontology_relationships(opt.merge!(:result => []))
        end
      end
    end

    opt[:result].uniq # redudant recursion is eliminated here?! #.sort{|x,y| x.part1.name <=> y.part1.name}
  end

  def self.auto_complete_search_result(params = {}) # :yields: Array of OntologyClasses
    tag_id_str = params[:tag_id]
    return [] if (tag_id_str == nil || params[:proj_id].blank? || params[tag_id_str.to_sym].nil?)

    value = params[tag_id_str.to_s]

    result = []

    value = value.split.join('%')

    # order our results
    result += OntologyClass.find(:all, :conditions => ["(labels.name = ? OR ontology_classes.id = ? OR ontology_classes.xref = ?) AND ontology_classes.proj_id = ?", value, value, value, params[:proj_id] ], :limit => 1, :include => [:labels] )
    result += OntologyClass.find(:all, :conditions => ["(labels.name LIKE ?) AND ontology_classes.proj_id = ?", "%#{value}%", params[:proj_id] ], :include => [:labels], :order => 'length(labels.name)' )
    result += OntologyClass.find(:all, :conditions => ["(definition LIKE ?) AND ontology_classes.proj_id = ?", "%#{value}%", params[:proj_id] ],  :include => [:labels] )
    
    result.uniq
  end

  # returns a String in the form of a flat js hash
  def js_flat_hash(options = {}) # :yield: String 
    @opt = {
      :max_depth => 999,
      :depth => 0,
      :children => [],
      :relationship_type => 'all' # or an Isa#id
    }.merge!(options.symbolize_keys)
    @opt[:depth] = @opt[:depth] + 1
    if @opt[:depth] < @opt[:max_depth]          
      self.child_ontology_relationships(@opt).each do |n|
        @opt[:children] << n
        n.ontology_class1.js_flat_hash(@opt)   
      end
    end
    return @opt[:children]
  end

  # returns a String in the form of a nested js hash
  def js_hash(options = {})
    @opt = {
      :max_depth => 999,
      :depth => 0,
      :string => '',
      :key_is_id => true, 
      :relationship_type => 'all' # or an Isa#id
    }.merge!(options.symbolize_keys)
    @opt[:depth] = @opt[:depth] + 1
    if @opt[:key_is_id]    
      @n = self.id
    else 
      @n = self.display_name.gsub(/[^a-zA-Z]/, "_") # these all have to be javascript variables, and then can't be used to round trip search, for things like "-"
    end

    if @opt[:depth] < @opt[:max_depth]          
      children = self.child_ontology_relationships(@opt) 

      if children.size == 0
        @opt[:string] << "#{@n}," # fake size this for the protovis stuff like "#{@n}:10," 
        return @opt[:string] 
      else
        if @opt[:depth] + 1 < @opt[:max_depth]
          @opt[:string] << "#{@n}:{"
        else
          @opt[:string] << "#{@n}:10,"
        end
      end

      children.each do |n|
        n.ontology_class1.js_hash(@opt)   
      end

      if @opt[:depth] + 1 < @opt[:max_depth]
        if children.size > 0
          @opt[:string] << "},"
        else 
          @opt[:string] << "}"
        end
      end
    end

    # hack, to deal with the extra "," in the "join" 
    return "{#{@opt[:string]}}".gsub(/\,\}/, "}") 
  end

  def js_hash2(options = {})
    @opt = {
      :max_depth => 999,
      :depth => 0,
      :string => '',
      :key_is_id => true, 
      :relationship_type => 'all' # or an Isa#id
    }.merge!(options.symbolize_keys)
    @opt[:depth] = @opt[:depth] + 1

    if @opt[:key_is_id]    
      @n = self.id
    else 
      @n = self.display_name.gsub(/[^a-zA-Z]/, "_") # these all have to be JS variables, and then can't be used to round trip search, for things like "-"
    end

    if @opt[:depth] < @opt[:max_depth]          
      children = self.child_ontology_relationships(@opt) 

      if children.size == 0
        @opt[:string] << "#{@n}:10,"
        return @opt[:string] 
      else
        if @opt[:depth] + 1 < @opt[:max_depth]
          @opt[:string] << "#{@n}:{"
        else
          @opt[:string] << "#{@n}:10," # this is a fake size 
        end
      end

      children.each do |n|
        n.ontology_class1.js_hash2(@opt)   
      end

      if @opt[:depth] + 1 < @opt[:max_depth]
        if children.size > 0
          @opt[:string] << "},"
        else 
          @opt[:string] << "}"
        end
      end
    end

    # hack, to deal with the extra "," in the "join" 
    return "{#{@opt[:string]}}".gsub(/\,\}/, "}").gsub(/\,/, "")
  end

  def self.generate_xrefs(options = {})
    opt = {
      :use_mx_ids => false,
      :proj_id => nil,
      :prefix => nil,
      :initial_value => nil,
      :padding => 7, 
      :ontology_classes => [] # OntologyClasses to be numbered
    }.merge!(options.symbolize_keys)  
    return false if !opt[:proj_id] || !opt[:prefix] || opt[:ontology_classes].size == 0

    opt[:initial_value] = OntologyClass.largest_xref_identifier(opt) + 1

    return false if opt[:initial_value].nil?

    i = opt[:initial_value].to_i

    OntologyClass.transaction do 
      begin
        opt[:ontology_classes].each do |oc|
          if oc.xref.blank?
            if opt[:use_mx_ids]
              oc.xref = "#{opt[:prefix]}:#{oc.id.to_s}" 
            else 
              oc.xref = "#{opt[:prefix]}:#{i.to_s.rjust(opt[:padding], "0")}" 
              while !oc.valid? 
                i += 1 
                oc.xref = "#{opt[:prefix]}:#{i.to_s.rjust(opt[:padding], "0")}" 
              end 
            end    
            oc.save
          end
        end 
      rescue ActiveRecord::RecordInvalid => e
        raise e 
      end
    end
    true 
  end

  # returns the largest integer in a xref of format prefix:integer or -1 if no ontology_classes with prefix exist
  def self.largest_xref_identifier(options = {})
    return false if options[:proj_id].nil?
    candidates = Proj.find(options[:proj_id]).ontology_classes.with_populated_xref.with_xref_namespace(options[:prefix]).ordered_by_xref
    candidates.size > 0 ? candidates.last.xref.split(":")[1].to_i : -1 
  end


  # requires :ontology_classes => [] and :proj_id
  def self.strip_candidacy_tags(options = {})
    opt = {
      :ontology_classes => [],
      :proj_id => nil 
    }.merge!(options.symbolize_keys)  
    return false if opt[:proj_id] == nil 
    proj = Proj.find(opt[:proj_id]) 
    return false if proj.ontology_inclusion_keyword.blank?
    begin
      OntologyClass.transaction do
        keywords_to_strip = proj.keywords.tagged_with_keyword(proj.ontology_inclusion_keyword)
        ocs = OntologyClass.tagged_with_keywords(:keywords => keywords_to_strip, :proj_id => opt[:proj_id])
        ocs.each do |p|
          p.tags.each do |t|
            t.destroy if keywords_to_strip.include?(t.keyword)
          end
        end
      end
    rescue
      return false
    end
  end

  ## pass params from OntologyController#proofer_batch_create and merge proj_id => id
  ## TODO: revise
  #def self.proofer_batch_create(params)
  #  raise "method needs revision after class/part split"
  #  begin
  #    @proj = Proj.find(params[:proj_id])
  #    raise if !@proj
  #    raise if params[:part].blank?
  #
  #    @count = 0
  #    params[:taxon_name_id] = params[:term][:taxon_name_id] if params[:term] && !params[:term][:taxon_name_id].blank? # handles batch loading from Proofer
  #    params[:ref_id] = params[:term][:ref_id] if params[:term] && !params[:term][:ref_id].blank? # handles batch loading from Proofer
  #
  #    @tn = TaxonName.find(params[:taxon_name_id]) unless params[:taxon_name_id].blank?
  #    @ref = Ref.find(params[:ref_id]) unless params[:ref_id].blank?
  #    @ontology_class_for_object_relationship = Part.find(params[:ontology_class_for_object_relationship_id]) unless params[:ontology_class_for_object_relationship_id].blank?
  #    @object_relationship = ObjectRelationship.find(params[:object_realtionship_id]) unless params[:object_relationship_id].blank?
  #
  #    ObjectRelationship.transaction do
  #      params[:part].keys.each do |p|
  #
  #        # TODO: new Term model, stats etc.
  #        te = TermExclusion.find_or_create_by_name_and_proj_id(params[:part][p], @proj.id) # BACKGROUND STATS ONLY
  #
  #        if params[:check][p]
  #          break if Part.find_by_name_and_proj_id(params[:part][p], @proj.id)
  #
  #          prt = Part.new(:name => params[:part][p])
  #          prt.obo_xref = params[:xref][p] if params[:xref] && params[:xref][p]
  #          prt.description = params[:description][p] if params[:description][p]
  #          prt.taxon_name = @tn if @tn
  #          prt.ref = @ref if @ref
  #          prt.save!
  #
  #          if @isa && @part_for_isa
  #            @relationship = Ontology.new(:part1_id => prt.id, :part2_id => @part_for_isa.id, :isa_id => @isa.id )
  #            @relationship.save!
  #          end
  #
  #          # add the tag here
  #          if !params[:tag].blank? && !params[:tag][:keyword_id].blank?
  #            tag = Tag.new(:keyword_id => params[:tag][:keyword_id], :addressable_type => 'Part', :addressable_id => prt.id)
  #            tag.notes = params[:tag][:notes] if !params[:tag][:notes].blank?
  #            tag.referenced_object = params[:tag][:referenced_object] if !params[:tag][:referenced_object].blank?
  #            tag.save!
  #          end
  #
  #          @count += 1
  #
  #          te.destroy # BACKGROUND STATS - we've used this term now, so it should be reset
  #        else # BACKGROUND STATS ONLY
  #          te.update_attributes(:count => te.count + 1)
  #        end
  #      end
  #    end
  #
  #  rescue Exception => e
  #    raise "#{e} on #{params[:part][p]}"
  #  end
  #
  #  return @count
  #end

  ## code below is from deprecated Part that needs complete rewrite

  ## TODO: logic is suboptimal, should use a gem engine for param combinations such
  ## needs complete rewrite
  #def self.param_search(params)
  #  raise "param_search not updated since deprecation"
  #  terms = []
  #  order = "ordered_by_#{params[:sort_order]}"
  #  @proj = Proj.find(params[:proj_id])
  #  if params[:edited]
  #    if params[:without_relationships]
  #      terms = @proj.parts.without_relationships.with_description_status(params[:definition]).with_xref_status(params[:xref]).changed_by(params[:person_id]).recently_changed(params[:time_ago].to_i.weeks.ago).send(order)
  #    else
  #      terms = @proj.parts.with_description_status(params[:definition]).with_xref_status(params[:xref]).changed_by(params[:person_id]).recently_changed(params[:time_ago].to_i.weeks.ago).send(order)
  #    end
  #  else
  #    if
  #      terms = @proj.parts.without_relationships.with_description_status(params[:definition]).with_xref_status(params[:xref]).not_changed_by(params[:person_id]).recently_changed(params[:time_ago].to_i.weeks.ago).send(order)
  #    else
  #      terms = @proj.parts.with_description_status(params[:definition]).with_xref_status(params[:xref]).not_changed_by(params[:person_id]).recently_changed(params[:time_ago].to_i.weeks.ago).send(order)
  #    end
  #  end
  #  terms
  #end

  # maintainence
  
  def self.update_all_sensu_positions(proj_id)
    begin
      OntologyClass.transaction do 
        Proj.find(proj_id).ontology_classes.each do |oc|
          puts "updating #{oc.id}"
          oc.update_sensu_positions
        end
      end
    rescue
        "barf"
    end
  end

  def update_sensu_positions 
    sensus.ordered_by_position.each_with_index do |s, i|
      puts "#{s.id} #{i}"
      s.update_attributes(:position => i) 
    end
  end

  # TODO: is this used? deprecate?
  def illustration_IP_vote=(value)
    # validate and/or Raise
    self.illustration_IP_votes = [] if self.illustration_IP_votes == nil
    self.illustration_IP_votes << value
  end

  def as_json
    return nil if xref.nil?
    return {:id => Ontology::OntologyMethods.obo_uri(self), :label => self.preferred_label.name}
  end

  def ontology_class_as_json
    return nil if xref.nil?
    xref = Ontology::OntologyMethods.obo_uri(self)
    h = Hash.new
    h[xref] = {}
    h[xref]['definition'] = definition
    h[xref]['label'] = self.preferred_label.name
    h[xref]['relationships'] = []
    primary_relationships.each do |pr|
      if !pr.ontology_class1.xref.nil? && !pr.ontology_class2.xref.nil?
        h[xref]['relationships'].push(
              {'subject' => pr.ontology_class1.as_json,
               'predicate' => pr.object_relationship.as_json,
               'object' => pr.ontology_class2.as_json}
                                       )
      end
    end
    h
  end

  def svg_as_json
    return nil if xref.nil?

    h = Hash.new
    h['markers'] = []

    h['class'] = self.as_json
    figure_markers.each do |fm|
      h['markers'].push(
                     {
                      'image' =>  fm.figure.image.path_for(:size => :medium),
                      'svg' => fm.svg
                     }
                    )
    end
    h
  end

  def self.all_uris # :yields Array of URIs for all 
    # TODO (fast)  
  end

  protected

  def ensure_that_labels_contains_obo_label
    if !self.obo_label_id.blank? && !self.labels.map(&:id).include?(self.obo_label_id)
      self.sensus << Sensu.create!(:label => Label.find(self.obo_label_id), :ontology_class => self, :ref_id => self.written_by_ref_id) 
    end
    true
  end



end
