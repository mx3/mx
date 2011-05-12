# == Schema Information
# Schema version: 20090930163041
#
# Table name: parts
#
#  id            :integer(4)      not null, primary key
#  name          :string(128)     not null
#  abbrev        :string(24)
#  description   :text
#  ref_id        :integer(4)
#  ref_page      :string(25)
#  notes         :text
#  taxon_name_id :integer(4)
#  language_id   :integer(4)
#  proj_id       :integer(4)      not null
#  creator_id    :integer(4)      not null
#  updator_id    :integer(4)      not null
#  updated_on    :timestamp       not null
#  created_on    :timestamp       not null
#  obo_dbxref    :string(255)
#  is_public     :boolean(1)
#  is_acronym    :boolean(1)  # DEPRECATED FOR TAGS

# !! THIS CLASS IS COMPLETELY DEPRECATED
# TODO: split of label, create obo_label_id for label

class PartOld < ActiveRecord::Base
  require 'obo_parser'
  require 'turm'

  has_standard_fields

  belongs_to :ref # the definition author source (strictly the text, not the definition concept)
  belongs_to :language
  
  has_many :tags, :as => :addressable, :dependent => :destroy, :include => [:keyword, :ref], :order => 'refs.cached_display_name ASC'  
  has_many :figures, :as => :addressable,  :order => :position, :dependent => :destroy # tags pertaining to a given reference
  has_many :keywords, :through => :tags
 
  # strictly housekeeping/counting utility for now
  has_many :parts_ref, :dependent => :destroy # a count TODO: pluralize and update
  has_many :parts, :through => :parts_ref

  # ontology related
  belongs_to :taxon_name # highest name applicable (for ont) TODO: revist, likely deprecate for Specimen level application 

  has_many :primary_relationships, :class_name => 'Ontology', :foreign_key => 'part1_id', :dependent => :destroy 
  has_many :secondary_relationships, :class_name => 'Ontology', :foreign_key => 'part2_id', :dependent => :destroy

  ## scope should now never include an order, sort with ordered_by_foo scopes

  scope :by_name, lambda {|*args| {:conditions => ["name = ?", (args.first ? "#{args.first}" : -1)]}}
  scope :by_fragment, lambda {|*args| {:conditions => ["name LIKE ? OR name LIKE ? OR name LIKE ?", (args.first ? "#{args.first}%" : -1), (args.first ? "%#{args.first}%" : -1), (args.first ? "#{args.first}%" : -1)]}}

  # descriptions = definition
  scope :without_descriptions, :conditions => {:description => nil} # , :order => 'created_on DESC, updated_on DESC, name'
  scope :with_description_status, lambda {|*args| {:conditions => (args.first ?  'description is not null'  : '' ) }}
  scope :with_description_containing, lambda {|*args| {:conditions => ["description like ?",  (args.first ? "%#{args.first}%" : -1)]}} 
  
  # should make this a mixin sensu StandardFields, because it will get use everywhere
  # Part.find(:all).tagged_with_keyword(12)
  scope :tagged_with_keyword, lambda {|*args| {:conditions => ["id IN (SELECT addressable_id FROM tags WHERE tags.addressable_type = 'Part' AND keyword_id = ?)", (args.first ? args.first : -1)]}}    

  # false returns everything, true returns those with xref set
  scope :with_dbxref_status, lambda {|*args| {:conditions => (args.first ? "obo_dbxref IS NOT NULL AND obo_dbxref != ''" : '') }}
    
  # namespace needs to be ?
  # checks to see if has complete dbxref - ks, 07.11.2009
  scope :with_complete_dbxref, lambda {|*args| {:conditions => ["obo_dbxref LIKE ?", args.first + ":%"]}} # :order => 'obo_dbxref', 
  
  scope :is_public, :conditions => {:is_public => true}
  # scope :not_acronym, :conditions => {:is_acronym => false}

  # if you pass a Term.id the scope is limited to those above it
  scope :without_relationships, lambda {|*args| {:conditions => ["id NOT IN (SELECT part1_id from ontologies) AND id NOT IN (SELECT part2_id from ontologies) AND id > ?", (args.first || -1)] }} # :order => 'created_on DESC, updated_on DESC, name', 

  # Part.recently_changed(1.day_ago) 
  scope :recently_changed, lambda {|*args| {:conditions => ["(parts.created_on > ?) OR (parts.updated_on > ?)", (args.first || 2.weeks.ago), (args.first || 2.weeks.ago)] }}
  scope :changed_by, lambda {|*args| {:conditions => ["(parts.creator_id = ?) OR (parts.updator_id = ?)", (args.first || -1), (args.first || -1)] }}
  scope :not_changed_by, lambda {|*args| {:conditions => ["(parts.creator_id != ?) AND (parts.updator_id != ?)", (args.first || -1), (args.first || -1)] }}
  scope :from_proj, lambda {|*args| {:conditions => ["parts.proj_id = ?", args.first || -1] }} # useful in refs case

  scope :with_first_letter, lambda {|*args| { :conditions => ["name LIKE ?", (args.first ? "#{args.first}%" : -1)]}} # :order => 'name',
  scope :tagged_with_keyword_string, lambda {|*args| { :conditions => ["parts.id IN (SELECT addressable_id FROM tags WHERE addressable_type ='Part' AND tags.keyword_id = (SELECT id FROM keywords WHERE keyword = '?'))", args.first ? "#{args.first}" : -1] }}

  # based on "reserved" keywords, pass a proj_id
  scope :synonyms, lambda {|*args| { :conditions => ["parts.id IN (SELECT addressable_id FROM tags WHERE addressable_type ='Part' AND tags.keyword_id = (SELECT id FROM keywords WHERE keyword = 'synonym' and keywords.proj_id = ?))", args.first ? "#{args.first}" : -1] }}
  scope :obsolete, lambda {|*args| { :conditions => ["parts.id IN (SELECT addressable_id FROM tags WHERE addressable_type ='Part' AND tags.keyword_id = (SELECT id FROM keywords WHERE keyword = 'obsolete' and keywords.proj_id = ?))", args.first ? "#{args.first}" : -1] }}

  scope :ordered_by_name, :order => 'name ASC'
  scope :ordered_by_id, :order => 'id ASC'
  scope :ordered_by_updated_on, :order => 'updated_on DESC'
  scope :ordered_by_created_on, :order => 'created_on DESC'
  scope :ordered_by_obo_dbxref, :order => 'obo_dbxref'

  # TODO: confirm deprecation, all relationships should be "valid" now
  # has_many :valid_relationships, :class_name => 'Ontology', :foreign_key => 'part1_id', :include => :isa,  :conditions => "isas.complement != 'is_a'"   # 'isa_id != 41 AND isa_id != 43']

  validates_presence_of :name 
  validates_uniqueness_of :abbrev, {:scope => "proj_id", :if => :abbrev?}
  
  validates_format_of :obo_dbxref, :with => %r{.*:.*}i, :message => 'must be in the format foo:bar', :if => Proc.new{|o| !o.obo_dbxref.blank?}  # weak, could be strengthened

  def validate_on_create
     if Part.find_by_taxon_name_id_and_name_and_proj_id(taxon_name_id, name, proj_id)
       errors.add("That part/taxon_name combination already exists, and")
    end
  end
  
  def before_destroy
    if !self.obo_dbxref.blank?
      errors.add("You can't destroy a term that has an existing dbxref.")
    end
  end

  # pass a Person 
  # TODO: deprecate for application_helper method or inherit via standard_fields?
  def created_or_admin(person)
    if person.id.to_i == self.creator_id.to_i || person.is_admin || person.is_ontology_admin
      true
    else
      false
    end
  end

  def unique_keywords
    self.keywords.uniq
  end

 # TODO: logic is suboptimal, should use a gem engine for param combinations such 
  def self.param_search(params)
    @terms = []
    order = "ordered_by_#{params[:sort_order]}"
    @proj = Proj.find(params[:proj_id])
    if params[:edited]
      if params[:without_relationships] 
        @terms = @proj.parts.without_relationships.with_description_status(params[:definition]).with_dbxref_status(params[:dbxref]).changed_by(params[:person_id]).recently_changed(params[:time_ago].to_i.weeks.ago).send(order)
      else
        @terms = @proj.parts.with_description_status(params[:definition]).with_dbxref_status(params[:dbxref]).changed_by(params[:person_id]).recently_changed(params[:time_ago].to_i.weeks.ago).send(order)
      end
    else
      if
        @terms = @proj.parts.without_relationships.with_description_status(params[:definition]).with_dbxref_status(params[:dbxref]).not_changed_by(params[:person_id]).recently_changed(params[:time_ago].to_i.weeks.ago).send(order)
      else 
        @terms = @proj.parts.with_description_status(params[:definition]).with_dbxref_status(params[:dbxref]).not_changed_by(params[:person_id]).recently_changed(params[:time_ago].to_i.weeks.ago).send(order)
      end 
    end
    @terms 
  end

  # returns a Hash of Part => [Parts]
  def self.labels_without_descriptions_used_in_descriptions(params)
    opts = {:proj_id => nil}.merge!(params) 
    if @proj = Proj.find(opts[:proj_id], :include => :parts)
      parts = {} 
      @proj.parts.without_descriptions.each do |p|
        descs = @proj.parts.with_label_used_in_klass_description(p.name)
        parts.merge!(p => descs) if descs.size > 0
      end
    else 
      return {} 
    end
    return parts
  end

  # TODO: DEPRECATE
  def synonymous_children
    children = []
    proj = Proj.find(self.proj_id)
    kw = proj.synonym_keyword
    (proj.tags.by_keyword(kw).with_referenced_object(":part:#{self.id}").by_class("Part") + proj.tags.with_referenced_object("#{self.obo_dbxref}").by_class("Part")).each do |t|
      children.push t.tagged_obj if t.referenced_object_object == self
    end
    children.sort{|a,b| a.display_name <=> b.display_name }
  end

  # TODO: DEPRECATE
  def homonymous_children
    children = []
    proj = Proj.find(self.proj_id)
    kw = proj.homonym_keyword
    (proj.tags.by_keyword(kw).with_referenced_object(":part:#{self.id}").by_class("Part") + proj.tags.with_referenced_object("#{self.obo_dbxref}").by_class("Part")).each do |t|
      children.push t.tagged_obj if t.referenced_object_object == self
    end
    children.sort{|a,b| a.display_name <=> b.display_name }
  end

  # TODO: DEPRECATE
  def synonymous_with
    self.tags.by_keyword(Proj.find(self.proj_id).synonym_keyword).collect{|t| t.referenced_object_object}
  end

  # TODO: DEPRECATE
  # def homonymous_with
  #  self.tags.by_keyword(Proj.find(self.proj_id).homonym_keyword).collect{|t| t.referenced_object_object}
  # end
 
  # returns an Array of String of the plural forms
  def plural_forms
    self.tags.by_keyword(Proj.find(self.proj_id).plural_keyword).collect{|t| t.notes}
  end

  # Array of Strings
  def all_labels
    plural_forms + [self.name]
  end

  # keys are labels, values are an array of ids, for mapping in Linker
  def hash_labels
    self.all_labels.inject({}){|h, l| h.merge(l => [self.id])}
  end

  # this now returns Ontologies
  # immediately attached children only (does not recurse) 
  def tree_child(options = {})
    opt = { # recursing with @opt is bad
      :relationship_type => 'all'  # or an Isa#id
    }.merge!(options.symbolize_keys)
    if opt[:relationship_type] == 'all'    
      Ontology.find(:all, :include => [:part1, :isa, :part2], :conditions => ['part2_id = ?', self.id]).sort{|x,y| x.part1.name <=> y.part1.name}
    else
      Ontology.find(:all, :include => [:part1, :isa, :part2], :conditions => ['part2_id = ? AND isa_id = ?', self.id, opt[:relationship_type]]).sort{|x,y| x.part1.name <=> y.part1.name}
    end 
  end

  # A precursor example of finding all transitive relationships, in this case defaulted  for is_a/part_of
  # returns a hash of Parts, with values == true when redundant relationships are implied 
  def logical_relatives(options = {})
    return [] if !Isa.find_by_interaction_and_proj_id('is_a', self.proj_id) || !Isa.find_by_interaction_and_proj_id('part_of', self.proj_id)

    rel1 = Proj.find(self.proj_id).isas.by_interaction('is_a').first.id
    rel2 = Proj.find(self.proj_id).isas.by_interaction('part_of').first.id
    return [] if !rel1 || !rel2 
    
    opt = { # recursing with @opt is bad
      :direction => :children,
      :rel1 => rel1,
      :rel2 => rel2 
    }.merge!(options.symbolize_keys)

    return nil if ![:parents, :children].include?(opt[:direction]) 

    first_result = []  # all the part_of
    second_result = [] # part_of through is_a
    
    result = {}

    # find/recurse the isa/part_of tree, this gets us a unique array of pertinent Ontologies
    rels = self.tree_relatives(opt.merge(:relationship_type => [opt[:rel1], opt[:rel2]]))

    return {} if rels == nil

    # get all the part_of resuls, anything below and with a part_of, is part_of (since all others are is_a)
    to_nuke = [] # index of rels to delete before next itteration
    rels.each do |r|
      nuke = false # boolean check for delete
      if r.isa_id == opt[:rel2]
        nuke = true
        if opt[:direction] == :parents
          first_result.push(r.part2) # yes a confusing model name
        else
          first_result.push(r.part1) 
        end
      end
      to_nuke.push(r) if nuke 
    end

    # !! don't do uniq on first result

    # try to invoke some loop speedup by deleting values we don't need to loop through  
    rels.delete_if{|r| to_nuke.include?(r)} 
    rels.delete_if{|r| !r.isa_id == opt[:rel1]} # we only need to deal with isas of rel1 now

    # for all of the part_of results also get the is_a children (or whatever rel2 -> rel1 relationship is)
    
    rels.each do |rel|
      first_result.uniq.each_with_index do |r,i|
        if opt[:direction] == :parents
          second_result.insert(-1, rel.part2) if (rel.part1 == r) 
        else
          second_result.insert(-1, rel.part1) if (rel.part2 == r)
        end
      end
    end 

    second_result.uniq! # don't imply redundancies from hitting an is_a twice (is this right?! - gives "correct" result AFAIKT)
    
    (first_result + second_result).each do |r|
      result.merge!(r => (!result.keys.include?(r) ? false : true)) 
    end

    result
  end

  # returns an array of Parts
 #def tree_relatives(options = {})
 #  opt = {                         # don't use @opt because this messes up other recursive calls 
 #    :relationship_type => 'all',  # 'all' or an array of [Isa#id, Isa#id2 ... ]
 #    :result => [],
 #    :depth => 0,                  # ? can't use :depth because it's tied to the other recurser
 #    :max_depth => 999,
 #    :direction => :children       # or :parents
 #  }.merge!(options.symbolize_keys)
 #  os = []
 #
 #  if opt[:direction] == :children
 #    cond = 'part2_id'
 #  else # else find parents
 #    cond = 'part1_id'
 #  end

 #  if opt[:depth] < opt[:max_depth] 
 #    opt[:depth] = opt[:depth] + 1
 #    if (opt[:relationship_type].to_s == 'all')
 #      os = Ontology.find(:all, :include => [:part1, :isa, :part2], :conditions => "#{cond} = #{self.id}")
 #    else
 #      sql = " (" + opt[:relationship_type].collect{|i| "isa_id = #{i}"}.join(" OR ") + ") "
 #      os = Ontology.find(:all, :include => [:part1, :isa, :part2], :conditions => "#{cond} = #{self.id} AND #{sql}")
 #    end
 #    
 #    opt[:result] += os
 #    os.each do |o|
 #      if opt[:direction] == :children
 #        opt[:result] = opt[:result] + o.part1.tree_relatives(opt.merge!(:result => []))
 #      else
 #        opt[:result] = opt[:result] + o.part2.tree_relatives(opt.merge!(:result => []))
 #      end
 #    end
 #  end

 #  raise "likely recursion error" if opt[:depth] > 50 # likely a recursion error
 #  opt[:result].uniq # redudant recursion is eliminated here?!   #.sort{|x,y| x.part1.name <=> y.part1.name}
 #end

  # recursive
  # TODO: deprecated?
  # Returns an array of Ontologies 
  def parents(options = {})
       @opt = {
         :relationship_type => 'all' # or an Isa#id
      }.merge!(options.symbolize_keys)
      if @opt[:relationship_type] == 'all'
        self.primary_relationships
      else
        self.primary_relationships.by_relationship(@opt[:relationship_type])
      end
   end

  # returns a String in the form of a flat js hash
  def js_flat_hash(options = {})
      @opt = {
        :max_depth => 999,
        :depth => 0,
        :children => [],
        :relationship_type => 'all' # or an Isa#id
     }.merge!(options.symbolize_keys)
      @opt[:depth] = @opt[:depth] + 1
      if @opt[:depth] < @opt[:max_depth]          
         self.tree_child(@opt).each do |n|
         @opt[:children] << n
           n.part1.js_flat_hash(@opt)   
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
       @n = self.name.gsub(/[^a-zA-Z]/, "_") # these all have to be javascript variables, and then can't be used to round trip search, for things like "-"
     end
   
     if @opt[:depth] < @opt[:max_depth]          
        children = self.tree_child(@opt) 
        
        if children.size == 0
          @opt[:string] << "#{@n}:10,"
          return @opt[:string] 
        else
          if @opt[:depth] + 1 < @opt[:max_depth]
            @opt[:string] << "#{@n}:{"
          else
            @opt[:string] << "#{@n}:10,"
          end
        end

        children.each do |n|
          n.part1.js_hash(@opt)   
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
       @n = self.name.gsub(/[^a-zA-Z]/, "_") # these all have to be JS variables, and then can't be used to round trip search, for things like "-"
     end
   
     if @opt[:depth] < @opt[:max_depth]          
       children = self.tree_child(@opt) 
        
      if children.size == 0
        @opt[:string] << "#{@n}:10,"
        return @opt[:string] 
      else
        if @opt[:depth] + 1 < @opt[:max_depth]
          @opt[:string] << "#{@n}:{"
        else
          @opt[:string] << "#{@n}:10,"
        end
      end

      children.each do |n|
        n.part1.js_hash2(@opt)   
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

  # return a Newick string representation of an Ontology
  # Is there a way to do the recursive traversal so the gsub cheat isn't neaded at the end?
# def newick_string(options = {})
#   @opt = {
#      :max_depth => 999,             # the maximum depth
#      :depth => 0,                   # the current depth
#      :string => '',                 # the returned string 
#      :relationship_type => 'all',   # or an array of Isa#ids !! careful for recusrion with is_a, part_of 
#      :labels => [],                 # contains all existing labels, so that labels can be modified for display
#      :parent => '',                 # internally referenced
#      :hilight_depth => 5,           # the maximum depth at which to highlight nodes/branches
#      :color => :random,             # see Part#_newick_color
#      :color_bin => [],              # as for labels,
#      :annotate_value => false,      # include value= (value checked in color) in the newick tree
#      :annotate_index => false,      # include index= (value transformed color) in the newick tree
#      :annotate_clades => false,     # include the !hilight= statement in the newick tree
#      :annotate_branches => false,   # include the !color= statement in the newick tree
#      :rel1 => Proj.find(self.proj_id).isas.by_interaction('is_a').first.id,
#      :rel2 =>  Proj.find(self.proj_id).isas.by_interaction('part_of').first.id
#   }.merge!(options.symbolize_keys)
#    return "ERROR: hilight_depth > max_depth" if @opt[:hilight_depth] > @opt[:max_depth]
#    # color methods valid for child coloration
#    child_color_methods = Part.newick_color_modes 
#    # Newick trees can only have unique terminal labels, make sure they are so
#    n = self.name.gsub(/'/,"-") # no apostrophes
#    if @opt[:labels].include?(n) 
#      n = "#{n}-"
#      while @opt[:labels].include?(n)
#       n = "#{n}-"
#      end 
#    end

#    @opt[:labels] << n                             # "remember" which labels we are using 
#    n = "'#{n}'"

#   if @opt[:depth] < @opt[:max_depth]              # render only as deep as requested 
#     @opt[:depth] = @opt[:depth] + 1
#     children = self.tree_child(@opt) 

#     # render the terminal labels and associated structure 
#     if children.size == 0
#       @opt[:string] << "#{n}"
#   
#       # color it?  (no labeling terminal branches)
#       if @opt[:hilight_depth] - @opt[:depth] + 1 > 0 && child_color_methods.include?(@opt[:color])
#         @opt[:string] << "[&#{_newick_color(@opt.merge(:hilight_children => 1))}]" 
#       end

#       @opt[:string] << "," 
#   
#       return @opt[:string] 
#     else
#       @opt[:string] << "#{n}"  
#    
#       # color it?  (no labeling terminal branches)
#       if @opt[:hilight_depth] - @opt[:depth] + 1 > 0 && child_color_methods.include?(@opt[:color])
#         @opt[:string] << "[&#{_newick_color(@opt.merge(:hilight_children => 1))}]" 
#       end

#       if @opt[:depth] + 1 < @opt[:max_depth] # look ahead
#         @opt[:string] << ",("
#       else
#         @opt[:string] << ","
#       end
#    
#     end

#     # recurse the children
#     @opt[:parent] = self.name
#     if @opt[:depth]  < @opt[:max_depth]   
#       children.each do |c|
#         c.part1.newick_string(@opt)   
#       end
#     end

#     # and add closing structure 
#     if @opt[:depth] + 1 < @opt[:max_depth] # look ahead 
#       @opt[:string] << ")"
#      
#       # color and label? 
#       if @opt[:hilight_depth] - @opt[:depth] + 1 > 0  && child_color_methods.include?(@opt[:color])
#         @opt[:string] <<  "[&!name=\"#{@opt[:parent]}\"" # give the preceeding branch/node a name
#         @opt[:string] << ",#{_newick_color(@opt)}" 
#         @opt[:string] << "]"
#       end
#       
#       (@opt[:string] << ",") if children.size > 0
#     end

#     end # end depth check

#   # hack, to deal with the extra "," in the "join" 
#   return "(#{@opt[:string]})".gsub(/\,\)/, ")") + ";" 
# end 

# def self.newick_color_modes
#   [:random, :tags, :depth, :immediate_part_of_children, :logical_children, :oldest_sensu_tag, :parts_refs, :parts_in_refs_count]
# end

# # returns a Figtree specific branch/node hilight statement, use only with Part#newick_tree
# def _newick_color(opt = {})
#   opt[:hilight_children] ||= self.tree_relatives(opt).size

#   i = -1 # color index/variable for width when :hilight_children == 1
#   s = -1

#   case opt[:color]
#   when :random
#     i = rand(10)
#     s = i
#     color = ColorHelper::palette(:index => i)  
#   when :jacknifed_random 
#     i = rand(10)
#     opt[:color_bin] = [] if opt[:color_bin].size == 10 
#     color = ColorHelper::palette(:index => i)
#     until !opt[:color_bin].include?(color) do
#       i = rand(10)
#       color = ColorHelper::palette(:index => i)
#     end
#     opt[:color_bin].push(color)
#    
#   when :depth # maxes at 8
#    # color = ColorHelper::hexstr_to_signed32int("ff00#{"%x" % (255 - opt[:depth] * 10)}00")
#     s = opt[:depth] 
#     i = s > 8 ? 8 : s 
#     color = ColorHelper::palette(:palette => :cb_seq_9_mh_green, :index => i) 
#   when :immediate_part_of_children
#     s = self.tree_child(:relationship_type => Proj.find(self.proj_id).isas.by_interaction('part_of').first.id).size
#     case s
#     when 0 
#       i = 0
#     when 1..8  
#       i = s
#     when 9..9999
#       i = 9
#     else
#       i = 0 
#     end 
#     color = ColorHelper::palette(:index => i, :palette => :cb_div_10_blue_red)
#   when :parts_refs
#    s = self.parts.size
#     case s
#     when 0..99 
#       i = s
#     when 100..10000
#       i = 100 
#     else
#       i = 0 
#     end 
#     color = ColorHelper::palette(:index => i, :palette => :blue_100)
#   when :parts_in_refs_count
#     s = self.parts_ref.inject(0){|sum, pr| sum += pr.total}
#     case s
#     when 0..99 
#       i = s
#     when 100..10000
#       i = 100 
#     else
#       i = 0 
#     end 
#     color = ColorHelper::palette(:index => i, :palette => :blue_100)


#   when :logical_children
#     s = self.logical_relatives.size
#     case s
#     when 0 
#       i = 0
#     when 1..8
#       i = s
#     when 9..99999
#       i = 9 
#     else
#       i = 0 
#     end 
#     color = ColorHelper::palette(:index => i, :palette => :cb_div_10_blue_red)

#   when :oldest_sensu_tag
#     s = self.oldest_tag_by_ref_year(Keyword.find_by_keyword_and_proj_id('sensu', self.proj_id))
#     oldest_year = 1870 
#     unit_range = 10 
#     if s.to_i < oldest_year && s.to_i != 0  
#       i = unit_range - 1 
#     elsif s == 0
#       i = 0
#     else
#       i = (((Time.now.year.to_i - (s.to_i == 0 ? Time.now.year.to_i : s.to_i)).to_f / (Time.now.year.to_i - oldest_year).to_f) * unit_range).to_i
#     end
#     s ||= 0
#     if i == 0
#       color = ColorHelper::palette(:index => 15, :palette => :grey_scale)  # white
#     else 
#       color = ColorHelper::palette(:index => i, :palette => :blues_10)
#     end

#   when :tags
#     s = self.tags.size
#     if s == 0
#      i = 0
#     elsif s > 9 
#      i = 9 
#     end
#     color = ColorHelper::palette(:index => i, :palette => :blues_10)
#   end

#   annotations = []
#   annotations << "!color=#{color}" if opt[:annotate_branches]
#   annotations << "!hilight={#{opt[:hilight_children]},0.0,##{color}}" if opt[:annotate_clades] && opt[:hilight_children] > 1
#   annotations << "value=#{s}" if opt[:annotate_value]
#   annotations << "index=#{i}" if opt[:annotate_index]

#   annotations.join(",")
# end

  # TODO: rename to clarify, this is all relationships in which self is present
  def children
    Ontology.find(:all, :conditions => "((part1_id = #{self.id}) OR (part2_id = #{self.id}))", :include => [:part2]).collect{|o| o.part2}
  end

  #  used in RelationBrowser
  def direct_children
    Ontology.find(:all, :conditions => "((part1_id = #{self.id}) OR (part2_id = #{self.id}))", :include => [:part1]).collect{|o| o.part1}
  end
  
  def relationships
    Ontology.find(:all, :conditions => "proj_id = #{self.proj_id} AND ((part1_id = #{self.id}) OR (part2_id = #{self.id}))", :include => [:isa] )
  end
 
  def display_name(options = {})
     @opt = {
      :type => :inline 
     }.merge!(options.symbolize_keys)
     s = ''
    case @opt[:type]
     when :inline
      s =  name
     else
      s = name
     end  
    s
  end
  
  def bioportal_link_display_name(bioportal_id)
    if bioportal_id != ""
      if obo_dbxref
        "<td><strong>#{self.display_name}</strong>,</td><td>#{self.bioportal_link(bioportal_id)}</td>"
      end
    end
  end

  def bioportal_link(bioportal_id)
    if bioportal_id != ""
      if obo_dbxref
        "http://bioportal.bioontology.org/visconcepts/#{bioportal_id.to_s}/?id=#{obo_dbxref.to_s}"
      else
        false
      end
    end
  end

  # returns the year (integer) of the  
  def oldest_tag_by_ref_year(kw)
    oldest = 9999
    self.tags.by_keyword(kw).each do |t|
      oldest = t.ref.year if !t.ref.blank? && !t.ref.year.blank? && t.ref.year.to_i < oldest
      foo = 1
    end
    return nil if oldest == 9999
    
    oldest
  end

  # TODO: named scope?
  # Takes a Keyword and returns an array of Tags
  # moved to Taggable
  def is_obsolete_for_OBO(obsolete_keyword)
    self.tags.collect{|t| t.keyword}.include?(obsolete_keyword)
  end

  # 
  # when producing obo file checks for dangling identifiers in relationships
  # TODO: DEPRECATE? this is not done or presently being used
  # def checks_for_dangling_identifiers
  #  relationships = []
  #  relationships << Part.find(:all, :conditions => "proj_id = #{self.proj_id}").collect{|v| v.obo_dbxref}
  #  db_xref = ""
  #  db_xref = self.obo_dbxref.collect{|x| (relationships.include?(x.obo_dbxref) && !x.obo_dbxref.blank?) ? "#{db_xref}" : nil }
  #  db_xref.size > 0 ? "#{db_xref}" : "" 
  # end

  # TODO: this is being used 
  # moved to helper as xref_tags_display_tag(object_class, xref_keyword)
  def xref_tags_display_text(xref_keyword)
    return "ERROR" if !xref_keyword
    t = ""
    t = self.tags.by_keyword(xref_keyword).collect{|x| !x.referenced_object.blank? ? "xref: #{x.referenced_object}" : nil}.compact.join("<br />")
    t.size > 0 ? "#{t}<br />" : ""
   end
 
  # return the list of synonyms for OBO formatted display 
  def OBO_synonym_tags_html(synonym_keyword)
    return "! ERROR: NO 'synonym' KEYWORD DEFINED<br />"  if !synonym_keyword
    parts = [] 
    
    self.synonymous_children.each do |t|   
      # if !t.is_acronym
       parts << "synonym: \"#{t.name}\" []"
      # end
    end
    parts.size > 0 ? "#{parts.join("<br />")}<br /> " : ""
  end

  # abstract this to all models 
  def self.tagged_with_keywords(options = {})
    @opt = {
      :search_with_and => false,
      :invert => false, # select without
      :keywords => [],
      :proj_id => nil
    }.merge!(options.symbolize_keys)

    return [] if @opt[:keywords] == [] || @opt[:proj_id] == nil

    sql = "proj_id = #{@opt[:proj_id]}"
   

    # TODO: the AND logic requries a new AND id IN for each kw
    if @opt[:search_with_and]
      if @opt[:invert]
        sql += " AND id NOT IN (SELECT id from parts WHERE proj_id = #{@opt[:proj_id]} " + @opt[:keywords].collect{|k| " AND id in (SELECT addressable_id FROM tags WHERE addressable_type = 'Part' and keyword_id = #{k.id})"}.join + ")"
      else
        @opt[:keywords].each do |k|
          sql += " AND id IN (SELECT addressable_id FROM tags WHERE addressable_type = 'Part' AND keyword_id = #{k.id})"
        end
      end
         else
       sql += " AND id #{@opt[:invert] ? 'NOT IN' : 'IN'} (SELECT addressable_id FROM tags WHERE addressable_type = 'Part' AND (" + @opt[:keywords].collect{|k| "keyword_id = #{k.id}"}.join(" OR ") + "))"
    end

    Part.find(:all, :conditions => sql, :order => :name)
  end

  # changed to MiscMethods#random
  def self.random_part(proj_id, in_public = false)
    if in_public
    @parts = Part.is_public.find(:all, :conditions => "proj_id = #{proj_id}")
    else
      @parts = Part.find(:all, :conditions => "proj_id = #{proj_id}")
    end
    @parts[rand(@parts.size)]
  end
 
  # moved to MiscMethods 
  ## need to test 
  def self.clone_from_project(from_proj) # assumes legal proj has been checked already, fails nicely (won't dupe)
    c = 0
    if proj = Proj.find(from_proj)
      for part in proj.parts
        p = part.clone # proj/creator etc. are set automagically!
        c += 1 if p.save
      end
    end
    return c
  end

  # ontology related methods

  def MB_link(options = {})
    @opt = {
      :taxon => nil,
      :overide_taxon => false
    }.merge!(options)
 
    @opt[:taxon] = self.taxon_name.name if @opt[:overide_taxon] && !self.taxon_name.blank? # if the part has a specified taxon use that

    #    http://www.morphbank.net/Browse/ByImage/?keywords=head+Hymenoptera&tsnKeywords=&spKeywords=&viewKeywords=&localityKeywords=&listField1=imageId&orderAsc1=DESC&listField2=&orderAsc2=ASC&listField3=&orderAsc3=ASC&numPerPage=20&resetOffset=&activeSubmit=1&tsnId_Kw=keywords&viewId_Kw=keywords&spId_Kw=keywords&localityId_Kw=keywords&offset=0&log=NO&log=NO
    #
    kw_str = [@opt[:taxon], self.name].compact.join("+")
    s = 'http://www.morphbank.net/Browse/ByImage/index.php?'
    s << "keywords=#{kw_str}"
    s << "&tsnKeywords=&spKeywords=&viewKeywords=&localityKeywords=&listField1=imageId&orderAsc1=DESC&listField2=&orderAsc2=ASC&listField3=&orderAsc3=ASC&numPerPage=20&resetOffset=&activeSubmit=1&tsnId_Kw=keywords&viewId_Kw=keywords&spId_Kw=keywords&localityId_Kw=keywords&offset=0&log=NO&log=NO"
  end

  ## -- OBO related methods -- ##

  # moved to helper as OBO_def_tag
  def display_OBO_def_tag
	  "def: \"#{self.clean_description_display}\" #{self.obo_dbxref_for_ref}<br />" if !self.description.blank? 
  end

  #TODO: confirm deprecation 
  # def obo_id
  #  # pads to a ten digit number for now  
  #  #was being used in list_OBO but not being used for now
  #  p = Proj.find(self.proj_id) 
  #  id_str = self.id.to_s.rjust(8, "0")
  #  return "#{p.ontology_namespace}:#{id_str}" if p.ontology_namespace
  #  "DEFAULT:#{id_str}" 
  # end

  #move to helper with _tag 
  def obo_dbxref_for_ref
    return "[mxOBO:needs_xref]" if !self.ref
    self.ref.db_xref_list
  end
 
  # moved to helper with _tag 
  def db_xref_REF_for_ref
      return "" if !self.ref
      self.ref.db_xref_REF_list
  end
 
  # deprecated for Strings#linearize 
  # removes new line and strips leading and trailing whitespace from obo definition when dumping file
  def clean_description_display
      self.description.gsub(/\n/, '').strip
  end

  # renders an SVG file
  # just messing around
  # should obviously use xml builder to do this
  def self.visualize_svg(proj_id)

  @xy = {}

   s = '<?xml version="1.0" standalone="no"?>
    <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
    "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
    <svg width="100%" height="100%" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'

    @x_offset = 10
    @y_offset = 10
    @x_grid = 20
    @y_grid = 20
    @groups_of = 50

    @parts = Proj.find(proj_id).parts #[300..500] #[0..400]

    @crh = {} # current radius hash - used to additively create concentric rings

    # map the co-ordinates of the x,y positions for future use, we do this several times, so calculate up front regardless of cost
    @parts.in_groups_of(@groups_of, false).each_with_index do |grp,y|
       grp.each_with_index do |p,x|
         @xy[p.id] = {:x => x * @x_grid + @x_offset, :y => y * @y_grid + @y_offset}
         @crh[p.id] = 8 # initialize the hash
       end
    end

    # draw links  
    s += '<g stroke="indigo" stroke-width="1" stroke-linecap="round" fill="none" stroke-opacity="0.4">'
    @parts.each do |p|
      p.primary_relationships.each do |pr|
        if @xy[pr.id]
          @xoff = (@xy[p.id][:x] - @xy[pr.id][:x]).abs.to_f/3.5
          @yoff = (@xy[p.id][:y] - @xy[pr.id][:y]).abs.to_f/3.5
          # the IF is a terrible excuse for not solving 
          s += "<path d = \"M #{@xy[p.id][:x]+5} #{@xy[p.id][:y]+5} Q
            #{(@xy[p.id][:x] > @xy[pr.id][:x] ? (@xy[pr.id][:x] + @xoff) : (@xy[p.id][:x] + @xoff).to_f)  + 5}
            #{(@xy[p.id][:y] > @xy[pr.id][:y] ? (@xy[pr.id][:y] + @yoff) : (@xy[p.id][:y] + @yoff).to_f)  + 5}
            #{@xy[pr.id][:x] + 5} #{@xy[pr.id][:y] + 5}  \" />"
        end
      end
    end
    s += '</g>'
 
   # radius graphics, each in context of previous size
   # relationships
    s += '<g stroke="cornflowerblue" fill="none" stroke-opacity="0.4">'
     @parts.each do |p|
       w = p.relationships.size
       if w > 0
           s+= "<circle cx =\"#{@xy[p.id][:x] + 5}\" cy =\"#{@xy[p.id][:y]+5}\" r=\"#{(@crh[p.id].to_f + (w/2).to_f)}\" stroke-width = \"#{w}\" />"
           @crh[p.id] += w
       end
    end
    s += '</g>'

    # tags
    s += '<g stroke="orange" fill="none" stroke-opacity="0.7">'
    @parts.each do |p|
       w = p.tags.count
       if w > 0
          s+= "<circle cx = \"#{@xy[p.id][:x] + 5}\" cy = \"#{@xy[p.id][:y]+5}\" r=\"#{(@crh[p.id].to_f + (w/2).to_f)}\" stroke-width = \"#{w}\"/>"
          @crh[p.id] += w # stroke adds to radius on either side!
       end
    end
    s += '</g>'

    # figures
    s += '<g stroke="purple" fill="none" stroke-opacity="0.6">'
     @parts.each do |p|
       w = p.figures.size
       if w > 0
           s+= "<circle cx =\"#{@xy[p.id][:x] + 5}\" cy =\"#{@xy[p.id][:y]+5}\" r=\"#{(@crh[p.id].to_f + (w/2).to_f)}\" stroke-width = \"#{w}\" />"
           @crh[p.id] += w
       end
    end
    s += '</g>'

   # draw the clickable obj, we have the x,y from Part.id
    s += '<g stroke="white" fill="none" stroke-width="1" stroke-opacity="0.9">'
    @parts.each do |p|
      s+= "<a xlink:href=\"/projects/#{proj_id}/ontology/show_term/#{p.id}\" xlink:title=\"#{p.name}\">"
      if p.description.blank?
       s+= "<rect x=\"#{@xy[p.id][:x]}\" y=\"#{@xy[p.id][:y]}\" width=\"10\" height=\"10\" style=\"fill:red;\"/>"
      else
       s+= "<circle cx =\"#{@xy[p.id][:x] + 5}\" cy =\"#{@xy[p.id][:y] +5}\" r=\"5\" style=\"fill:green;\" />"
      end
      s+= "</a>"
    end
    s += '</g>'

    s += '</svg>' # close the page
    s
  end

  def self.fill_blank_xrefs(options = {})
    @opt = {
      :use_mx_ids => false,
      :proj_id => nil,
      :prefix => nil,
      :initial_value => 1,
      :padding => 7, 
      :parts => [] # parts to be numbered
    }.merge!(options.symbolize_keys)  

    return false if !@opt[:proj_id] || !@opt[:prefix] || @opt[:parts].size == 0
    i = @opt[:initial_value].to_i

    Part.transaction do 
      begin
        @opt[:parts].each do |p|
          if p.obo_dbxref.blank?
            if @opt[:use_mx_ids]
              p.obo_dbxref = "#{@opt[:prefix]}:#{p.id.to_s}" 
            else 
              p.obo_dbxref = "#{@opt[:prefix]}:#{i.to_s.rjust(@opt[:padding], "0")}" 
              while !p.valid? 
                i += 1 
                p.obo_dbxref = "#{@opt[:prefix]}:#{i.to_s.rjust(@opt[:padding], "0")}" 
              end 
            end    
            p.save
          end
        end 
      rescue ActiveRecord::RecordInvalid => e
        raise e 
      end
    end
     true 
  end

  # requires :parts => [] and :proj_id
  def self.strip_candidacy_tags(options = {})
    @opt = {
      :parts => [],
      :proj_id => nil 
    }.merge!(options.symbolize_keys)  
    return false if @opt[:proj_id] == nil 
    @proj = Proj.find(@opt[:proj_id]) 
    return false if @proj.ontology_inclusion_keyword.blank?
      begin
      Part.transaction do
        keywords_to_strip = @proj.keywords.tagged_with_keyword(@proj.ontology_inclusion_keyword)
        parts = Part.tagged_with_keywords(:keywords => keywords_to_strip, :proj_id => @opt[:proj_id])
        parts.each do |p|
          p.tags.each do |t|
            t.destroy if keywords_to_strip.include?(t.keyword)
          end
        end
      end
    rescue
      return false
    end
  end

  # parses simple files like:
  #   term, option defintion 
  #   term, option defintion 
  #   ... 
  #   term, option defintion 
  
  def self.batch_verify_simple(opt = {})
    params = opt[:params] 
 
    if params[:temp_file][:file].blank?
      return false 
    end

    result = {:taxon_name => nil, :ref => nil, :part_for_isa => nil, :isa => nil, :terms => Turms::Turms.new} # see /lib, Turms is a utility class 

    result[:taxon_name] = TaxonName.find(params[:term][:taxon_name_id]) if params[:term] && !params[:term][:taxon_name_id].blank?
    result[:ref] = Ref.find(params[:term][:ref_id]) if params[:term] && !params[:term][:ref_id].blank?
    result[:part_for_isa] = Part.find(params[:term][:part_id_for_is_a]) if params[:term] && !params[:term][:part_id_for_is_a].blank?
    result[:isa] = Isa.find(params[:term][:isa_id]) if params[:term] && !params[:term][:isa_id].blank?
    
    data = params[:temp_file][:file].read.split(/\n/).inject([]){|sum, l| sum << l.split(/,/, 2)}

    data.each do |t, definition|
      if @t = Part.find_by_name_and_proj_id(t.strip, opt[:proj])
        w = Turms::Turm.new(@t)
        w.definition = definition.strip if definition  # see if it matches
        result[:terms].existing.push(w) 
      else
        w = Turms::Turm.new(t)
        w.definition = definition.strip if definition
        result[:terms].not_present.push(w) 
      end
    end
    return result
  end

  # takes :params and :proj_id
  def self.batch_create_simple(opt = {})
    params = opt[:params]

    @count = 0
    @tn = TaxonName.find(params[:taxon_name_id]) if !params[:taxon_name_id].blank?
    @ref = Ref.find(params[:ref_id]) if !params[:ref_id].blank?
    @part_for_isa = Part.find(params[:part_for_isa_id]) if !params[:part_for_isa_id].blank?
    @isa = Isa.find(params[:isa_id]) if !params[:isa_id].blank?

    begin
      Part.transaction do
        for p in params[:part].keys
          if params[:check][p]
            
            prt = Part.new(:name => params[:part][p])
            prt.taxon_name = @tn if @tn
            prt.ref = @ref if @ref
            prt.description = params[:definition][p] if params[:definition][p]
            prt.save!
           
            # add the realtionships 
            if @isa && @part_for_isa
              relationship = Ontology.new(:part1_id => prt.id, :part2_id => @part_for_isa.id, :isa_id => @isa.id )
              relationship.save!
            end
    
            # add the tag here
            if params[:tag] && params[:tag][:keyword_id]
              tag = Tag.new(:keyword_id => params[:tag][:keyword_id], :addressable_type => 'Part', :addressable_id => prt.id)
              tag.notes = params[:tag][:notes] if !params[:tag][:notes].blank?
              tag.referenced_object = params[:tag][:referenced_object] if !params[:tag][:referenced_object].blank?
              tag.save!
            end

            @count += 1
          end
        end
      end

    rescue 
      return false
    end
  end


  # pass params from OntologyController#proofer_batch_create and merge proj_id => id 
  def self.proofer_batch_create(params)
    begin
      @proj = Proj.find(params[:proj_id])
      raise if !@proj 
      raise if params[:part].blank? 

      @count = 0
      params[:taxon_name_id] = params[:term][:taxon_name_id] if params[:term] && !params[:term][:taxon_name_id].blank? # handles batch loading from Proofer
      params[:ref_id] = params[:term][:ref_id] if params[:term] && !params[:term][:ref_id].blank? # handles batch loading from Proofer
      
      @tn = TaxonName.find(params[:taxon_name_id]) unless params[:taxon_name_id].blank?
      @ref = Ref.find(params[:ref_id]) unless params[:ref_id].blank?
      @part_for_isa = Part.find(params[:part_for_isa_id]) unless params[:part_for_isa_id].blank?
      @isa = Isa.find(params[:isa_id]) unless params[:isa_id].blank?

      Part.transaction do
        params[:part].keys.each do |p|

          te = TermExclusion.find_or_create_by_name_and_proj_id(params[:part][p], @proj.id) # BACKGROUND STATS ONLY

          if params[:check][p]
            break if Part.find_by_name_and_proj_id(params[:part][p], @proj.id)
            
            prt = Part.new(:name => params[:part][p])
            prt.obo_dbxref = params[:dbxref][p] if params[:dbxref] && params[:dbxref][p]
            prt.description = params[:description][p] if params[:description][p]
            prt.taxon_name = @tn if @tn
            prt.ref = @ref if @ref
            prt.save!
            
            if @isa && @part_for_isa
              @relationship = Ontology.new(:part1_id => prt.id, :part2_id => @part_for_isa.id, :isa_id => @isa.id )
              @relationship.save!
            end
    
            # add the tag here
            if !params[:tag].blank? && !params[:tag][:keyword_id].blank?
              tag = Tag.new(:keyword_id => params[:tag][:keyword_id], :addressable_type => 'Part', :addressable_id => prt.id)
              tag.notes = params[:tag][:notes] if !params[:tag][:notes].blank?
              tag.referenced_object = params[:tag][:referenced_object] if !params[:tag][:referenced_object].blank?
              tag.save!
            end

            @count += 1

            te.destroy # BACKGROUND STATS - we've used this term now, so it should be reset
          else # BACKGROUND STATS ONLY 
             te.update_attributes(:count => te.count + 1) 
          end
        end
      end

    rescue Exception => e
      raise "#{e} on #{params[:part][p]}"
    end
     
    return @count 
  end


  ## Methods to move to Label with Part becomes Label
  # 
  # Label
  #  id
  #  name
  #  proj_id
  #  creator_id
  #  updator_id
  #  created_on
  #  updated_on

  # :usages_in_klass_descriptions
  scope :with_label_used_in_klass_description, lambda {|*args| {:conditions => ["description LIKE ?", (args.first ? "%#{args.first}%" : -1)]}}

  ## Klass to ultimately deprecate when Part becomes Klass 
 
  # this will become a :through to Labels 
  has_many :klass_labels, :class_name => "Sensu", :foreign_key => 'label_id', :dependent => :destroy
  
  ## Klass keepers
  # these methods will be part of the evolved Klass object
  has_many :sensus, :foreign_key => 'klass_id', :dependent => :destroy # Klass relationshpip now (as opposed to label)

  # labels for a Klass (keep for now)
  # now an Array of Parts (will be Labels) 
  def labels # for this Part == klass
    self.sensus.ordered_by_label.collect{|s| s.label}.uniq
  end

  # now an Array of Parts (will be Labels) 
  # this Klass is involved in a homonymous relationships with these labels 
  def homonymous_labels
    labels = []
    self.sensus.excluding_klass(self.id).ordered_by_label.collect{|s| s.label}.uniq.each do |lbl|
      labels.push(lbl) if lbl.labels.size > 1 
    end
    labels
  end

end
