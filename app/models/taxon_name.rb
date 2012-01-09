
class TaxonName < ActiveRecord::Base
  has_standard_fields  

  include ModelExtensions::Taggable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::Identifiable

  ICZN_RANKS = %w{n/a superfamily family subfamily tribe subtribe genus subgenus species subspecies variety}.reverse!
 
  has_many :proj_taxon_names
  has_many :projs, :through => :proj_taxon_names
  has_many :immediate_children, :class_name => "TaxonName", :foreign_key => "parent_id", :order => "l"
  has_many :ipt_records, :dependent => :destroy
  has_many :otus 
  has_many :synonyms, :class_name => 'TaxonName', :foreign_key => 'valid_name_id'
  has_many :taxon_hists, :include => :ref, :order => "refs.year"
  has_many :type_specimens
  has_many :type_material, :through => :type_specimens, :source => :specimen, :order => :type_type

  belongs_to :original_genus, :class_name => "TaxonName", :foreign_key => "orig_genus_id"
  belongs_to :original_subgenus, :class_name => "TaxonName", :foreign_key => "orig_subgenus_id"
  belongs_to :original_species, :class_name => "TaxonName", :foreign_key => "orig_species_id"
  belongs_to :ref
  belongs_to :type_geog, :class_name => "Geog", :foreign_key => "type_geog_id"
  belongs_to :type_repository, :class_name => "Repository", :foreign_key => "type_repository_id"
  belongs_to :status, :class_name => "TaxonNameStatus", :foreign_key => "taxon_name_status_id"
  belongs_to :type_taxon, :class_name => "TaxonName", :foreign_key => "type_taxon_id"
  belongs_to :valid_name, :class_name => "TaxonName", :foreign_key => "valid_name_id"

  scope :ordered_by_date_of_availability, :order => '"taxon_names.year" ASC, refs.year ASC', :include => [{:ref => :authors}]

  # because of indexing we can't validate_presence_of parent_id here
  validates_presence_of :iczn_group
  validates_presence_of :name
  validate :format_of_name
  validate :format_of_iczn_group 
  validate :that_agreement_name_used_only_for_species_group_names 
  validate :that_species_group_names_do_not_have_family_group_parents

  def original_combination_genus
    original_genus ? original_genus : obj_at_rank('genus')
  end

  def original_combination_subgenus
    original_subgenus ? original_subgenus : obj_at_rank('subgenus')
  end

  def original_combination_species
    original_species ? original_species : obj_at_rank('species')
  end

  # note that the root TaxonName can be added but needs to be saved (again) if this is used to create. 
  def self.create_new(options = {}) # :yields: TaxonName
    # requires :person => Person, :taxon_name => {params for TaxonName}
    opt = {
    }.merge!(options).to_options!
    @taxon_name = TaxonName.new(opt[:taxon_name])

    if !opt[:person]
      @taxon_name.errors.add(:base, "Invalid or no person provided.")
      return @taxon_name
    end
   
    if @taxon_name.temp_parent_id && @taxon_name.temp_parent_id != ""
      p = TaxonName.find(@taxon_name.temp_parent_id)
      
      @taxon_name.errors.add(:base, "Species names can not have family group parents.") if (p.iczn_group != 'genus' && ['species', 'variety'].include?(opt[:taxon_name][:iczn_group]))
      if opt[:person] && p.in_ranges?(opt[:person].editable_taxon_ranges)
        if @taxon_name.save
          if !@taxon_name.set_parent(p)
            @taxon_name.errors.add(:base, "Failed to set parent to #{p.display_name}")
          end
        end
      else
        @taxon_name.errors.add(:base, "You do not have permission to add children to #{p.display_name}")
      end
    else
      @taxon_name.errors.add(:base, "You must specify a parent")
    end      
    @taxon_name
  end

  # Takes a self#decompose and creates all the names necessary?
  def self.multi_create(options = {})
    @opt = {
    }.merge!(options).to_options!
  end

  # returns a Hash with name pieces
  def self.decompose(name)
    # Foo Bar stuff things (Person/People, maybe with space), Year
    # Foo Bar stuff things Person,People maybe with space, Year
    # Foo Bar stuff things Person
    # Foo stuff things (Person)
    # Foo stuff things Person
  
  end

  # TODO: protected?
  def move_checking_permissions(new_parent, old_parent, person)
    if new_parent.in_ranges?(person.editable_taxon_ranges) && old_parent.in_ranges?(person.editable_taxon_ranges)
      if !self.move(new_parent)
        #        self.errors.add(:base, "Failed to set parent to #{new_parent.cached_display_name}")
        self.errors.add(:parent_id, "Failed to set parent to #{new_parent.cached_display_name}")

      end
    else
      #      self.errors.add(:base, "You do not have permission to alter parent #{new_parent.cached_display_name} or #{old_parent.cached_display_name}")

      self.errors.add(:parent_id, "You do not have permission to alter parent #{new_parent.cached_display_name} or #{old_parent.cached_display_name}")
    end
  end

  def self.set_visibility(params = {})
    params.to_options!
    if params[:taxon_name] && params[:taxon_name][:id] && !params[:taxon_name][:id].blank?
      if !ProjTaxonName.combination_exists(params[:proj_id], params[:taxon_name][:id])
        ProjTaxonName.create!(:proj_id => params[:proj_id], :taxon_name_id => params[:taxon_name][:id])
      end
    end
    ProjTaxonName.destroy(params[:name_to_remove]) if params[:name_to_remove]
  end

  def self.load_from_batch(params)
    params.to_options!
    @taxon_names = []
    raise ParseError.new('No file provided.') if params[:temp_file][:file].blank?
    
    names = params[:temp_file][:file].read.split(/\r\n|\r|\n/).map{|l| l.split(/\t/)} # wow line endings SUCK
    raise ParseError.new('Problem with input file, no rows?.') if names == nil || names.size == 0 
  
    names.each do |n|
      @taxon_names.push(TaxonName.new(:name => n[0], :author => (n[1] || nil), :year => (n[2] || nil)))
    end

    @taxon_names
  end

  def self.create_from_batch(params) 
    params.to_options!
    i = 0 
    self.transaction do 
      params[:name].keys.each do |n|
        if !TaxonName.find_by_name_and_parent_id(params[:name][n], params[:taxon_name_id])
          if TaxonName.create_new(:taxon_name => {:name => params[:name][n], :iczn_group => params[:iczn_group], :author => params[:author][n] , :year => params[:year][n], :parent_id => params[:taxon_name_id]}, :person => params[:person]).valid?
            i += 1 
          end
        end
      end
    end
    i
  end

  def species_name_to_use # :yields: String 
    # If a species name is now in comination with a genus for which it needs a new gender that name is the new defacto name
    self.agreement_name.blank? ? self.name : self.agreement_name
  end

  def year_of_publication # :yields: String
    (year.blank? ? (ref.year.blank? ? '' : ref.year  )  : year).to_i
  end

  def display_name(options = {})
    opt = {
      :type => :cached,
      :target => "" # xml  
    }.merge!(options.symbolize_keys)

    # you must build with xml and return xml to support :target
    xml = Builder::XmlMarkup.new(:target => opt[:target])

    case opt[:type]
    when :for_select_list
      case rank
      when "subspecies"
        xml <<  "#{get_parent_name('genus')} #{get_parent_name('species')} #{species_name_to_use}"
      when "species"
        xml <<  "#{get_parent_name('genus')} #{species_name_to_use}"
      when "subgenus"
        xml << "#{get_parent_name('genus')} (#{species_name_to_use})"
      when "genus"
        xml << "#{name}"
      else
        xml << name
      end
    when :selected
      self.display_name(:target => xml, :type => :for_select_list)
      # TODO?
    when :fancy_name # meh, should move to helper, but we do need this "atom" (italics, no author year)
      case rank
      when "subspecies"
        xml.i "#{get_parent_name('genus')} #{get_parent_name('species')} #{species_name_to_use}"
      when "species"
        xml.i "#{get_parent_name('genus')} #{species_name_to_use}"
      when "subgenus"
        xml.i "#{get_parent_name('genus')} (#{name})"
      when "genus"
        xml.i "#{name}"
      else
        xml << name 
      end
    when :original_combination
      case rank
      when 'genus', 'subgenus','species', 'subspecies'
        xml << ['<i>', original_combination_genus ? original_combination_genus.name : '<i>PARENT ERROR: No Genus provided</i>', 
          (original_combination_subgenus ? "(#{original_combination_subgenus.name})" : nil),
          (original_combination_species ? original_combination_species.name : nil),
          (rank == 'subspecies' ? name : nil), '</i>',
          self.author_year
        ].compact.join(" ")
      else
        xml << self.display_name(:type => :name_with_author_year)
      end
    when :name_with_author_year
      xml << (self.display_name(:type => :fancy_name) + " #{self.display_author_year}" )
    when :short_name_with_author_year
      xml << (self.species_name_to_use + " #{self.display_author_year}" ).strip
    when :string_no_author_year # doesn't include subgenera, should be :name_without_author_year
      case rank
      when "subspecies"
        xml << "#{get_parent_name('genus')} #{get_parent_name('species')} #{species_name_to_use}"
      when "species"
        xml << "#{get_parent_name('genus')} #{species_name_to_use}"
      when "subgenus"
        xml << "#{get_parent_name('genus')} (#{name})"
        xml << "#{name}"
      else
        xml << name
      end
    when :string_with_author_year
      xml << (self.display_name(:type => :string_no_author_year) + " #{self.display_author_year}" ).strip
    else 
      xml << (cached_display_name || "ERROR - cached_display_name has not yet been built, contact your adminstrator!")
    end
    return opt[:target]
  end

  # DEPRECATED
  # TODO: deprecate for :select_option or some such
  def display_for_list 
    case rank
    when "subspecies"
      "#{get_parent_name('genus')} #{get_parent_name('species')} #{species_name_to_use}"
    when "species"
      "#{get_parent_name('genus')} #{species_name_to_use}"
    when "subgenus"
      "#{get_parent_name('genus')} (#{name})"
    when "genus"
      "#{name}"
    else
      name
    end
  end

  # DEPRECATED
  # TODO: move to display_name sensu specimens
  # htmlized version 
  def fancy_name
    case rank
    when "subspecies"
      "<i>#{get_parent_name('genus')} #{get_parent_name('species')} #{species_name_to_use}</i>"
    when "species"
      "<i>#{get_parent_name('genus')} #{species_name_to_use}</i>"
    when "subgenus"
      "<i>#{get_parent_name('genus')} (#{name})</i>"
    when "genus"
      "<i>#{name}</i>"
    else
      name
    end
  end

  def italicize?
    true if self.iczn_group == 'species' || self.iczn_group == 'genus'
  end

  # this is hit via has_standard_fields on before_validation
  def update_cached_display_name
    self.cached_display_name = self.display_name(:type => :fancy_name) 
  end

  def self.iczn_groups
    ["species", "genus", "family", "variety", "form", "n/a"] # n/a => not applicable
  end
   
  # TODO: is this repeated somewhere? 
  def self.type_types
    ["holotype", "lectotype", "syntype", "neotype"]
  end

  def species_index_url
    s = 'http://speciesindex.org/iczn/' # we don't handle botany yet
    case self.rank
    when 'family', 'subfamily'
      s += "fam/#{self.species_name_to_use}"
    when 'genus'
      s += "gen/#{self.species_name_to_use}"
    when 'subgenus' # this isn't handled yet?
      s += "subgen/" + [self.name_at_rank('genus'), self.species_name_to_use].join("/")
    when 'species'
      s += "sp/" + [self.name_at_rank('genus'), self.species_name_to_use].join("/")
    when 'subspecies'
      s += "subsp/" + [self.name_at_rank('genus'), self.name_at_rank('species'), self.species_name_to_use].join("/") # may have to update for subgenera
    else
      return nil
    end
        
    s += "/#{self.year}" if !self.year.blank? 
    s
  end

  def taxonomic_history
    # needs to return all the names that are synonymous as well
    'stub'
  end
 
  def all_names
    # the darwin core full chain
    'stub'
  end

  def is_genus_or_species_group
    ((self.iczn_group == 'species') or (self.iczn_group == 'genus')) ? true : false
  end
 
  # returns the parent genus GROUP object, subgenus or genus
  # used! (NOT TECHNICALLY CORRECT FOR author names, which only look at genus, not subgenus)
  def genus_group # :yields: TaxonName
    case rank # self.rank
    when "subspecies"
      p1 = self.parent # must be a species
      return p1.parent # must be a genus
    when "species"
      return self.parent
    when "subgenus"
      return self
    when "genus"
      return self
    else
      nil
    end
  end
  
  def orig_genus # :yields: TaxonName | nil
    return orig_genus_id if orig_genus_id # the trivial case, we've specifically identified where it was described
    # if original genus id is not given assume its parent links to the original genus
    o = obj_at_rank('genus') # can return a nil results
    return o.id if o
    nil
  end
  
  # Assumes all families have parents (to return a family)
  def obj_at_rank(r) # :yields: TaxonName || nil
    node = self
    node = node.parent until ((node.rank == r) or (not node.parent))
    node.parent ? node : nil
  end

  def name_at_rank(rank) # :yields: String || ""
    node = self
    node = node.parent until ((node.rank == rank) or (not node.parent))
    node.parent ? node.species_name_to_use : ""
  end
  
  # returns the name of parent at a given rank (including self if self is at that rank)
  # if the rank is lower self.rank returns self.name (odd behaviour?)
  # if no name at that rank exists returns the top parent
  # only really practical when you want to return a species/genus/family
  ## REDUNTANT WITH ABOVE vs NIL, but careful to delete ##
  def get_parent_name(rank)
    node = self
    node = node.parent until ((node.rank == rank) or (not node.parent))
    node.species_name_to_use
  end

  # author / year can also be rendered from the attached reference 
  # if EITHER year or AUTHOR are provided for the taxon name then the ref is NOT used, even if only one of the two is given
  # TODO: this is nasty because parens SHOULD be calculated, and not provided, as such both work now
  # TODO: provide a warning where calculation and existing parens don't match
  def display_author_year # :yields: String, includes automatic detection of parens 
    s = author_year
    # check for parentheses  
    if (self.author =~ /\(|\)/) || (self.parent_id && self.parent.obj_at_rank('genus') && (iczn_group == 'species') && !(orig_genus_id == nil) && (self.parent.obj_at_rank('genus').id != orig_genus_id) && (s.to_s.length > 0) )
      return "(#{s.gsub(/\(|\)/,"")})" # we gsub off in case they were originally provided
    end
    s
  end

  def author_year # :yields: String, unparenthesized author and year (see also display_author_year)
    # necessary for original combinations
    s = ''
    # logic is given author year over-rides reference author year!
    if !author.blank? || !year.blank?
      s = [(author.blank? ? "author not provided" : author), year].reject{|i| i.blank?}.join(", ")
    end
    if s.length == 0 
      s = ref.authors_for_taxon_name if !ref_id.blank?
    end 
    s
  end

  # TODO: deprecate for specimens
  def display_type_locale
    s = ''
    s << "#{type_locality} " if type_locality?
    s << "[#{type_geog.display_name}]" if type_geog_id?
    s 
  end
 
  # TODO: move the heck out of here 
  # this is here just so the controller can call sanitize_sql
  def self.clean(text)
    sanitize_sql(text)
  end
 
  # return this taxon_name's family name parent 
  def parent_family ## prolly a faster way to parse this
    ps = self.parents
    ps.push(TaxonName.find(self.id)) # we might only have partially filled taxon name (i.e. without .name) ... really?
    ps.each do |p|
      if p.iczn_group == 'family'
        if p.species_name_to_use[-4, 4] == "idae"
          return p
        elsif p.rank == 'n/a'
          return nil
        end
      end
    end
    return nil
  end

  # returns this taxon_name's subfamily name parent 
  def parent_subfamily ## prolly a faster way to parse this
    ps = self.parents
    ps = [TaxonName.find(self.id)] + parents # we might be a subfamily!
    for p in ps
      if p.iczn_group == 'family'
        if p.species_name_to_use[-4, 4] == "inae"
          return p
        elsif p.rank == 'n/a'
          return nil
        end
      end
    end
    return nil
  end

  def rank ## ASSUMES things are attached through families - not necessarily true, but relatively safe 
    # easy one first
    if iczn_group == "n/a"
      "n/a"
    elsif iczn_group == "family"
      if name[-5, 5] == "oidea"
        "superfamily" 
      elsif name[-4, 4] == "idae"
        "family"
      elsif name[-4, 4] == "inae"
        "subfamily"
      elsif name[-3, 3] == "ini"
        'tribe'
      elsif name[-3, 3] == "inii"
        'subtribe'
      end
    elsif not parent # needed to prevent errors if there are node w/o parents
      nil
    elsif iczn_group == "genus"
      if parent.iczn_group == "genus"
        "subgenus"
      elsif parent.iczn_group == "family"
        "genus"
      end
    elsif iczn_group == "species"
      if parent.iczn_group == "species"
        "subspecies"
      elsif parent.iczn_group == "genus"
        "species"
      end
    else
      nil
    end
  end

  # TODO: revist vs. agreement_name 
  def self.find_for_auto_complete(conditions, table_name)
    self.find_by_sql "SELECT #{table_name}.*, p.name as parent_name FROM taxon_names AS #{table_name}
      LEFT JOIN taxon_names AS p ON #{table_name}.parent_id = p.id 
      WHERE #{sanitize_sql(conditions)} 
      ORDER BY #{table_name}.name ASC limit 50"
  end  
  
  def in_ranges?(ranges)
    ranges.each do |range|
      return true if range === l and range === r
    end
    return false
  end

  # TODO: move to named scope for OTUs
  def child_otus(proj_id) # returns OTUs attached to THIS taxon name AND children of this TaxonName, as bound by project  (should be "self_and_child_otus")
    Otu.find_by_sql(
      "SELECT DISTINCT o.*
        FROM (taxon_names as tn INNER JOIN otus o ON tn.id= o.taxon_name_id)
        WHERE ((tn.l >= #{self.l}) AND (tn.r <= #{self.r}) AND (o.proj_id = #{proj_id}) )
        ORDER BY tn.l, o.name;") # tweak order with caution
  end
  
  def child_otus_in_group(otu_group_id, proj_id) # returns OTUs attached to children of this TaxonName if they are in the otu group specified, as bound by project 
    Otu.find_by_sql(
      "SELECT DISTINCT o.*  
      FROM (otu_groups_otus AS ogo INNER JOIN otus o ON ogo.otu_id = o.id) INNER JOIN taxon_names AS tn ON o.taxon_name_id = tn.id 
      WHERE ((tn.l >= #{self.l}) AND (tn.r <= #{self.r}) AND (o.proj_id = #{proj_id}) AND (ogo.otu_group_id = #{otu_group_id}) )
      ORDER BY o.name;")
  end

  def image_descriptions(proj_id) # returns all the image descriptions for this taxon name AND its children (i.e. those tied to OTUs)
    ImageDescription.find_all_by_otu_id(self.child_otus(proj_id).collect{|o| o.id})
  end  
  
  # def before_update
  #   if $person_id and l and r
  #     raise "You do not have permission to alter this taxon_name" unless self.editable_by?($person_id)
  #   end
  # end
  #
  # def before_destroy
  #   if $person_id and l and r
  #     errors.add(:base, "You do not have permission to destroy this taxon_name") unless self.editable_by?($person_id)
  #   end
  # end
  #
  # def editable_by?(person_id)
  #   Person.find(person_id).editable_taxon_ranges.each do |range|
  #     return true if range === l and range === r
  #   end
  #   return false
  # end

   
  #########################################################################
  # NESTED SET MADNESS
  #########################################################################

  # this is all pre Krishna's et al.'s  better_nested_set, which we should port to eventually
  
  # acts_as_tree establishes the parent/child associations, adding the 
  # methods #parent, #children as well as #root, #roots, and #siblings.
  #* need to abstract this and add to the 'act' code
  acts_as_tree :order => "name" ## if abstracting this, we would want to be able to use self.class.order_snippet here

  #* need to abstract this
  attr_protected :l, :r
  
  def parents # :yields: Array of TaxonNames
    # the immediate parent will be the first element in the array
    self.class.find(:all, :conditions => "#{self.class.scope_condition} AND 
      (#{self.class.left_column} < #{self.left} AND #{self.class.right_column} > #{self.right})", 
      :order => "#{self.class.left_column} DESC")
  end
  
  def full_set ## This is all chldren of a given taxon including self ?!
    self.class.find(:all, :conditions => "#{self.class.scope_condition} AND 
      (#{self.class.left_column} >= #{self.left} AND #{self.class.right_column} <= #{self.right})", 
      :order => "#{self.class.left_column} DESC")
  end
    
  def set_parent(p)
    raise "Object not yet saved" if self.new_record?
    self.reload
    raise "Parent already set" if self.parent
    raise "Being your own parent won't work" if self == self.parent
    raise "Setting the parent of a node with children not supported" unless self.children.empty?
    left_bound = find_insertion_point(p)
    self.transaction do
      self.class.slide(2, left_bound)
      self.left = left_bound + 1
      self.right = left_bound + 2
      self.parent = p
      self.save         
    end
    return true
  end
  
  # if there was ever a method that merited unit testing...
  #* test scope of new parent?
  #* need to ensure that current parent is in same tree as new parent
  def move(new_parent) # :yields: TaxonName
    self.reload
    new_parent.reload
    raise "Intended parent is a child of this node or is this node" if (new_parent.left >= left) and (new_parent.right <= right)
    raise "Intended parent is a family for a species group name" if new_parent.iczn_group == 'family' && self.iczn_group == 'species'
  
    left_bound = find_insertion_point(new_parent)
    gap_size = right - left + 1
    self.transaction do   
      self.class.slide(gap_size, left_bound) # open
      self.reload # gets the new left and right in case our own sub-tree got shifted
      correction = left_bound + 1 - left
      self.class.move_sub_tree(correction, left, right)
      self.class.slide( - gap_size, right) # close
      # careful will overwrite changes if don't reload
      self.reload
      self.parent = new_parent
      self.save
    end
  end
  
  # CHECKS/TESTING 
  def self.check_all_quick
    return false if roots.size > 1
    return false unless self.count("((l IS NULL) OR (r IS NULL))") == 0
    total = self.count
    return false unless total == self.count_by_sql("select count(distinct(l)) as `count(*)` from taxon_names")
    return false unless total == self.count_by_sql("select count(distinct(r)) as `count(*)` from taxon_names")
    
    max_r = find(:first, :order => "r desc").right
    min_l = find(:first, :order => "l asc").left
    return false unless max_r - min_l + 1 == total * 2
    return true
  end
  
  # everything in the table
  def self.check_all
    roots.each{|r| return false unless r.check_subtree}
    return true
  end
  
  # one node and everything below it
  def check_subtree
    if children.empty?
      return false unless left and right
      # puts "NO children: left = #{left}, right = #{right}, expected: #{left + 1}" unless right - left == 1
      right - left == 1
    else
      n = left
      for c in (children)
        return false unless c.left and c.right
        return false unless c.left == n + 1        
        return false unless c.check_subtree
        n = c.right
      end
      # puts "children: left = #{left}, right = #{right}, expected: #{n + 1}" unless right == n + 1
      right == n + 1
    end
  end
  
  # Rebuild/index the l, r values
  # $person_id must be set to run this from the console.  This can take a longish for large trees
  def self.renumber_all 
    begin
      TaxonName.transaction do
        roots.each{|r| r.renumber_subtree}
      end
      return true
    rescue
      raise # uncomment when running from console for more error checking
      # return false
    end
  end
  
  def renumber_subtree(n = 1)
    self.left = n
    if children.empty?
      self.right = (n += 1)
    else
      for c in (children)
        n = c.renumber_subtree(n + 1)
      end
      self.right = (n += 1)
    end
    $person_id = self.updator_id
    raise "Record #{self.id} is invalid" unless self.save
    return n
  end
    
  #== Internal methods
  #---------------------------------------------#
  #* assumption: root nodes defined as: parent_id IS NULL OR == 0
  #* assumption: no external code tries to directly alter lft, rgt or parent_id
  #* currently does not support deletion of nodes with children
  #* currently cannot merge 2 trees
   
  #* need to abstract
  # this is to prevent code outside the model from messing up the numbering
  def l=(ignore) end
  def r=(ignore) end
    
  def parent_id=(p_id)
    @temp_parent_id = p_id # used for set_parent and move
  end
  def temp_parent_id
    @temp_parent_id
  end

  before_create :intialize_l_r
  def intialize_l_r
    self.left = 1
    self.right = 2
  end
  
  def verify_no_children
    raise "has children" unless children.empty?
  end
  
  #*  this is specific to the taxon name stuff 
  # Override the destroy method because AR will automatically delete 
  # the children (the acts_as_tree bit unfortunately sets that up)
  def destroy
    verify_no_children
    super
  end

  after_destroy :slide_gaps
  def slide_gaps
    #* NOTE: currently the children are :dependent, so get destroyed automatically.
    #* that is slow... need to use prune if not dependent
    # self.class.prune(left, right)
    gap_size = right - left + 1
    self.class.slide( - gap_size, left)
  end
    
  ################ protected ? ##################
  
  def self.move_sub_tree(correction, old_left_bound, old_right_bound)
    update_all( "#{left_column} = (#{left_column} + (#{correction})), #{right_column} = (#{right_column} + (#{correction}))", 
      "#{scope_condition} AND #{left_column} >= #{old_left_bound} AND #{right_column} <= #{old_right_bound}")
  end

  # opens or closes a gap in the numbering (a negative gap_size closes)
  def self.slide(gap_size, left_bound)
    update_all( "#{left_column} = #{left_column} + (#{gap_size})",  "#{scope_condition} AND #{left_column} > #{left_bound}" )
    update_all( "#{right_column} = #{right_column} + (#{gap_size})",  "#{scope_condition} AND #{right_column} > #{left_bound}" )
  end
  
  # remove a branch (but not the current node)
  def self.prune(left_bound, right_bound)
    delete_all("#{scope_condition} AND #{left_column} > #{left_bound} AND #{right_column} < #{right_bound}")
  end
        
  #find the number above which we insert.
  # keeping the left-right numbers sorted according to some criteria allows you to 
  # return an ordered heirarchical tree, something that cannot be accomplished with
  # a regular :order parameter (as seen in has_many)
  def find_insertion_point(new_parent)
    # the parent could be a moving target, so we reload
    new_parent.reload
    conditions = self.class.scope_condition + 
      " AND ((#{self.class.parent_column} = #{new_parent.id}) OR (#{self.class.id_column} = #{self.id}))" # added brackets here
    sibs = self.class.find(:all, :conditions => conditions, :order => self.class.order_snippet)
    # the :order parameter is used to get the children, 
    # so they should be ordered correctly
    
    my_index = sibs.index(self)
    if my_index == 0
      return new_parent.left
    else
      return sibs[my_index - 1].right
    end
  end
  
  # this would be replaced with the configuration parameters
  def self.left_column; "l" end
  def self.right_column; "r" end
  def self.scope_condition; "1 = 1" end
  def self.order_snippet; "name" end
  def self.parent_column; "parent_id" end
  def self.id_column; "id" end

  # this wouldn't -- convenience methods to make the code cleaner
  def right; self[self.class.right_column] end
  def left; self[self.class.left_column] end
  def right=(val) self[self.class.right_column] = val end
  def left=(val) self[self.class.left_column] = val end  
    
  #########################################################################
  # END NESTED SET MADNESS
  #########################################################################

  protected

  def that_agreement_name_used_only_for_species_group_names 
    errors.add(:agreement_name, "is only applicable to species group names. The species must also presently be in a different genus than originally described.") if ( (!self.agreement_name.blank?) && ((self.iczn_group != "species") || ((self.orig_genus_id.blank?) && (self.orig_subgenus_id.blank?)) ) )
  end

  def format_of_name
    if name != 'root'
      errors.add(:name, "is not capitalized and is not a species-group or varietal name, capitalize and/or use 'original spelling' if needed") if ((self.species_name_to_use =~ /\A[a-z].*/) && (!["species", "variety"].include?(self.iczn_group))   )
      errors.add(:name, "is capitalized and not a genus-group name or higher, remove capitalization and use 'original spelling' if needed") if ((self.species_name_to_use =~ /\A[A-Z].*/) && (self.iczn_group == "species"))
      errors.add(:name, "can not contain whitespace or non-latinized alphabet, use original spelling to indicate the form as provided in publication if needed") if self.species_name_to_use =~ /[^a-zA-Z|\-]/
      return false if errors.size > 0
    end
    true
  end

  # this should likely not be modified to accept non-governed names
  def format_of_iczn_group
    errors.add(:name, "iczn group is not one of family, genus, species, or n/a") if !ICZN_RANKS.include?(iczn_group)
  end

  def that_species_group_names_do_not_have_family_group_parents
    # hit on updates only, see self.create_new
    if (name != 'root') && !self.new_record?
      errors.add(:parent_id, "invalid: species/varietal names require species or genus group parents.") if (['species', 'variety'].include?(self.iczn_group) && ['family', 'n/a', 'other'].include?(self.parent.iczn_group))
    end
  end
  
end


