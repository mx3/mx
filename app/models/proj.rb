# == Schema Information
# Schema version: 20090930163041
#
# Table name: projs
#
#  id                            :integer(4)      not null, primary key
#  name                          :string(255)     not null
#  hidden_tabs                   :text
#  public_server_name            :string(255)
#  unix_name                     :string(32)
#  public_controllers            :text
#  public_tn_criteria            :string(32)
#  default_institution_repository_id 
#  starting_tab                  :string(32)      default("otu")
#  default_ontology_id           :integer(4)
#  default_content_template_id   :integer(4)
#  gmaps_API_key                 :string(90)
#  creator_id                    :integer(4)      not null
#  updator_id                    :integer(4)      not null
#  updated_on                    :timestamp       not null
#  created_on                    :timestamp       not null
#  ontology_namespace            :string(32)
#  default_ontology_term_id      :integer(4)
#  obo_remark                    :text
#  ontology_inclusion_keyword_id :integer(4)
#  ontology_exclusion_keyword_id :integer(4)
#

class Proj < ActiveRecord::Base
  has_standard_fields
  
  serialize :hidden_tabs # store as array
  serialize :public_controllers
  
  has_many :associations, :dependent => :destroy
  has_many :association_supports # destroyed through associations. this is here so ref merging is smoother
  has_many :ces, :dependent => :destroy ## not sure if we want to destroy specimens/ lots through this
  has_many :chrs, :order => 'chrs.position, chrs.name ASC', :dependent => :destroy
  has_many :chr_groups, :order => "position, name", :dependent => :destroy
  has_many :chromatograms # destroyed through pcr

  has_many :key_couplets, :class_name => "Clave", :dependent => :destroy
  has_many :claves, :class_name => "Clave", :conditions => 'claves.parent_id is null'
  
  # make this a scope
  has_many :public_claves, :class_name => "Clave", :conditions => "claves.is_public = 1", :order => 'couplet_text'
 
  has_many :codings, :dependent => :destroy 
  has_many :confidences, :order => "position", :dependent => :destroy
  has_many :contents, :dependent => :destroy
  has_many :content_templates, :order => 'content_templates.name', :dependent => :destroy

  has_many :content_templates_content_types, :foreign_key => 'foo_id'

  has_many :public_content_templates, :class_name => 'ContentTemplate', :conditions => 'content_templates.is_public is true'
  has_many :public_matrices, :class_name => 'Mx', :conditions => 'mxes.is_public is true'
  has_many :content_types, :order => 'content_types.name', :dependent => :destroy
  has_many :text_content_types, :class_name => 'ContentType', :order => 'name', :conditions => 'sti_type = "TextContent"' # destroyed through content_types
  has_many :distributions # destroyed through otu
  has_many :extracts # destroyed through lot or specimen
  has_many :figures # not really required, but there for ease of use. destroyed through images
  has_many :figure_markers # not really required, but there for ease of use. destroyed through images
  has_many :gel_images, :dependent => :destroy
  has_many :genes, :order => 'position, name', :dependent => :destroy
  has_many :gene_groups, :order => 'name', :dependent => :destroy
  has_many :images, :dependent => :destroy ## don't destroy? ## SHARED ACROSS PROJECTS, need to update to reflect this  
  has_many :image_descriptions, :dependent => :destroy
  has_many :keywords, :order => 'keyword', :dependent => :destroy
  has_many :lots, :dependent => :destroy
  has_many :lot_groups, :dependent => :destroy
  has_many :measurements, :dependent => :destroy
  has_many :mxes, :order => "name", :dependent => :destroy
  has_many :multikeys, :class_name => 'Mx', :conditions => "is_multikey = 1" # subset of mxes
  has_many :public_multikeys, :class_name => 'Mx', :conditions => "is_multikey = 1 AND is_public = 1" # subset of mxes
  has_many :news, :dependent => :destroy
  
  # TODO: remove have HAO task complete
  # has_many :parts, :dependent => :destroy # :order => 'name' don't require this, use named scopes
  # has_many :isas, :order => "position", :dependent => :destroy

  # TODO: move to all scopes
  # TODO: add general purpose scope for is_public in standard fields
  has_many :current_public_news, :class_name => "News",  :conditions => (["is_public = 1 AND expires_on > ?", Time.now]), :order => "updated_on DESC"
  has_many :recent_public_news, :class_name => "News", :conditions => "is_public = 1", :limit => 4, :order => "updated_on DESC"
  has_many :all_public_news, :class_name => "News", :conditions => "is_public = 1", :order => "updated_on DESC"
  
  has_many :object_relationships, :dependent => :destroy 
  has_many :ontology_classes, :dependent => :destroy 
  has_many :ontology_relationships, :dependent => :destroy 
  has_many :terms, :dependent => :destroy
  has_many :labels, :dependent => :destroy

  has_many :otus, :dependent => :destroy
  has_many :otu_groups, :order => "name", :dependent => :destroy
  has_many :pcrs, :dependent => :destroy
  has_many :primers, :order => 'name ASC', :dependent => :destroy
  has_many :protocols, :dependent => :destroy
  has_many :sensus, :dependent => :destroy
  has_many :seqs, :dependent => :destroy
  has_many :specimens, :dependent => :destroy
  has_many :standard_views, :order => 'name', :dependent => :destroy
  has_many :standard_view_groups, :order => 'name', :dependent => :destroy
  has_many :tags, :dependent => :destroy
  has_many :ipt_records, :dependent => :destroy  

  has_and_belongs_to_many :people, :order => 'people.last_name'
  
  has_many :projs_refs, :order => :position
  has_many :refs, :through => :projs_refs, :order => 'refs.cached_display_name'
  
  # TODO: R3 check
  #has_and_belongs_to_many :refs_without_serials, :class_name => 'Ref', :conditions => {:serial_id => nil}, :order => 'refs.cached_display_name'

  ## can't use :taxon_names as a has_many for various reasons- it's defined in a def
  # has_many :taxon_names, :through => :proj_taxon_names
  has_many :proj_taxon_names, :include => :taxon_name, :order => 'taxon_names.cached_display_name ASC', :dependent => :destroy
  has_many :visible_taxon_names, :through => :proj_taxon_names, :source => :taxon_name, :order => 'taxon_names.cached_display_name ASC'

  # TODO: scope for TaxonName
  has_many :public_taxon_names, :through => :proj_taxon_names, :conditions => 'projs_taxon_names.is_public = 1', :order => 'taxon_names.cached_display_name ASC', :source => :taxon_name
  
  belongs_to :default_content_template, :foreign_key => 'default_content_template_id', :class_name => "ContentTemplate"
  belongs_to :default_ontology, :class_name => "Proj", :foreign_key => 'default_ontology_id'
  belongs_to :default_ontology_class, :class_name => "OntologyClass", :foreign_key => 'default_ontology_class_id'
  belongs_to :default_specimen_identifier_namespace, :class_name => "Namespace", :foreign_key => 'default_specimen_identifier_namespace_id'
  belongs_to :ontology_inclusion_keyword, :class_name => "Keyword", :foreign_key => 'ontology_inclusion_keyword_id'
  belongs_to :ontology_exclusion_keyword, :class_name => "Keyword", :foreign_key => 'ontology_exclusion_keyword_id'
  belongs_to :default_institution, :class_name => 'Repository', :foreign_key => 'default_institution_repository_id' # to where the specimens/data belong

  scope :is_eol_exportable, :conditions => 'projs.is_eol_exportable = true'

  validates_length_of :name, :minimum => 2, :message => "Project name must be longer than 2."
  validates_uniqueness_of :name, :message => "A project of that name already exists."
  validates_uniqueness_of :public_server_name, :if => :public_server_name?, :message => "An identical public server name already exists."

  validate :check_record
  def check_record
    if self.public_server_name_changed? && !self.public_server_name.blank?
      public_server_name.split(";").each do |n|
        if p = Proj.return_by_public_server_name(n)
          errors.add(:public_server_name, "One or more of the provided server name(s) already exist in another project.") if p.id != self.id
        end
      end
    end
  end

  def self.return_by_public_server_name(name) # :yields: Proj | nil 
    return nil if not(name =~ /\w*\.\w*/) # get a better matcher...
    if foo = Proj.find(:first, :conditions => ['public_server_name LIKE ?', "%#{name}%"]) 
      foo.public_server_name.split(/;/).include?(name) ? foo : nil # recheck vs. partial matches
    else
      nil
    end
  end

  def display_name(options = {})
    name
  end

  def ontology_id_to_use
    default_ontology_id.blank? ? id : default_ontology_id 
  end

  def ontology_server_name
    Rails.env.production? ? Proj.find(self.ontology_id_to_use).public_server_name : '127.0.0.1:3000'
  end

  # TODO: OBVIOUSLY NOT DONE
  def images_across_projs
    # return a list of Images (only) that are linked through ImageDescriptions, spanning all projects
    # Image.find(:all)   
    false
  end

  # TODO: this is largely deprecated 
  def self.tn_criteria_choices
    ["visible and public", "repository"]
  end
  
  def taxon_names
    TaxonName.find(:all, :conditions => "(#{sql_for_taxon_names})", :order => "name")    
  end
  
  def species_group_names
    TaxonName.find(:all, :conditions => "iczn_group = 'species' AND (#{sql_for_taxon_names})")
  end

  def genus_group_names
    TaxonName.find(:all, :conditions => "iczn_group = 'genus' AND (#{sql_for_taxon_names})")
  end

  def family_group_names
    TaxonName.find(:all, :conditions => "iczn_group = 'family' AND (#{sql_for_taxon_names})")
  end

  def site
    if self.public_server_name?
      # public server name should not be like www.foo.com but rather foo.com
      public_server_name.split(".").first 
    elsif self.unix_name?
      self.unix_name
    else
     'foo' #  raise # 'foo' # raise - something has been misconfigured
    end
  end
   
  # TODO: this is deprecated now? handled in application.rb
  def home_controller
    if @public
      "/public/site/#{site}/home"
    else
      "/public/site/#{site}/home" # extracted projects/#{self.id}
    end
  end
   
  # TODO: move to TaxonName 
  # pagination can't use the proj.taxon_names method, so 
  # instead we create an SQL string it can use.
  # the table_name is useful for joins.
  ## note the string needs to be wrapped in () for it work as intended in most cases! 
  def sql_for_taxon_names(table_name = nil, option = :visible)
    method = ( option == :public ? "public_taxon_names" : "visible_taxon_names")
    if table_name
      prefix = table_name + "."
    else
      prefix = ""
    end
   
    if self.send(method).size > 0
      self.send(method).collect{|t| "(#{prefix}l BETWEEN #{t.l} AND #{t.r})"}.join(" OR ")
    else
      "FALSE"
    end
  end
  
  #################################################################
  # These methods are used for public display of taxon names
  #################################################################
  
  def public_tn_sql(table = nil)
    if public_tn_criteria == "repository"
      prefix = table ? "#{table}." : nil
      "#{prefix}type_repository_id = #{self.default_institution_repository_id}"
    else
      self.sql_for_taxon_names(table, :public)
    end
  end
  
  def public_families
    if public_tn_criteria == "repository"
      families_for_repository
    else
      visible_families
    end
  end
  
  def public_letters(family)
    if public_tn_criteria == "repository"
      letters_for_repository(family)
    else
      visible_letters(family)
    end 
  end
  
  def public_genera(family, letter = "")
    if public_tn_criteria == "repository"
      genera_for_repository(family, letter)
    else
      visible_genera(family, letter)
    end     
  end
  
  def public_species(genus)
    if public_tn_criteria == "repository"
      species_for_repository(genus)
    else
      visible_species(genus)
    end   
  end

  # TODO: migrate all this to scopes.
  # For showing all visible names
  def visible_families
    # right now the count is the number of species
    TaxonName.find_by_sql(
    "SELECT p.*, count(*) as count FROM 
      (SELECT * FROM taxon_names t WHERE t.iczn_group = 'family' AND RIGHT(t.name,4) = 'idae') AS p
    LEFT JOIN 
      (SELECT id, l, r FROM taxon_names t2 WHERE #{self.sql_for_taxon_names('t2', :public)} AND iczn_group = 'species') AS c 
    ON p.l < c.l AND p.r > c.r
    WHERE c.id IS NOT NULL 
    GROUP BY p.id ORDER BY name")      
  end

  # returns all the families (taxon_name) that bound the OTUs bound to taxon names that occur in a given OTU group (confused?)
  # DOES NOT RESTRICT by visibility of TAXON NAME!
  def visible_families_by_otu_group(og) 
    TaxonName.find_by_sql("
      SELECT DISTINCT taxon_names.*
      FROM 
        (SELECT ogo.otu_group_id, tn.id, tn.r, tn.l
          FROM otu_groups_otus AS ogo INNER JOIN (otus AS o INNER JOIN taxon_names AS tn ON o.taxon_name_id = tn.id) ON ogo.otu_id = o.id
          WHERE (ogo.otu_group_id = #{og})
        ) as a
        INNER JOIN taxon_names ON (a.r <= taxon_names.r) AND (a.l >= taxon_names.l)
        WHERE (taxon_names.iczn_group = 'family' AND RIGHT(taxon_names.name,4) = 'idae') ORDER by a.l;")
  end

  def visible_genera_by_otu_group(og) 
    TaxonName.find_by_sql(
    "SELECT p.*, count(*) as count FROM 
      (SELECT t.* FROM (otu_groups_otus AS ogo INNER JOIN otus o ON ogo.otu_id = o.id) INNER JOIN taxon_names t ON o.taxon_name_id = t.id 
      WHERE (t.iczn_group = 'genus' AND ogo.otu_group_id = #{og})
     ) AS p
    LEFT JOIN 
      (SELECT  DISTINCT t2.id, t2.l, t2.r 
        FROM (otu_groups_otus AS ogo INNER JOIN otus ON ogo.otu_id = otus.id) INNER JOIN taxon_names AS t2 ON otus.taxon_name_id = t2.id
        WHERE (#{self.sql_for_taxon_names('t2', :public)} AND (t2.iczn_group = 'species')  ) 
       ) AS c 
    ON p.l < c.l AND p.r > c.r
    WHERE c.id IS NOT NULL 
    GROUP BY p.id ORDER BY p.name")      
  end
  
  def visible_letters(family)
    TaxonName.find_by_sql(
    ["SELECT p.*, count(*) as count FROM 
      (SELECT t.l, t.r, LEFT(t.name,1) as letter FROM taxon_names t 
        LEFT JOIN taxon_names f ON t.l > f.l AND t.r < f.r AND f.name = ?
        WHERE t.iczn_group = 'genus' AND f.id IS NOT NULL
      ) AS p
    LEFT JOIN 
      (SELECT id, l, r FROM taxon_names t2 WHERE #{self.sql_for_taxon_names('t2', :public)}) AS c 
    ON p.l < c.l AND p.r > c.r
    WHERE c.id IS NOT NULL 
    GROUP BY p.letter ORDER BY p.letter", family])
  end
  
  def visible_genera(family, letter = "")
    TaxonName.find_by_sql(
    ["SELECT p.*, count(*) as count FROM 
      (SELECT t.* FROM taxon_names t 
        LEFT JOIN taxon_names f ON t.l > f.l AND t.r < f.r AND f.name = ?
        WHERE t.iczn_group = 'genus' AND t.name like ? AND f.id IS NOT NULL
      ) AS p
    LEFT JOIN 
      (SELECT id, l, r FROM taxon_names t2 WHERE #{self.sql_for_taxon_names('t2', :public)}) AS c 
    ON p.l < c.l AND p.r > c.r
    WHERE c.id IS NOT NULL 
    GROUP BY p.id ORDER BY name", family, "#{letter}%"])
  end
  
  def visible_species(genus) # need brackets around self.sql_for_taxon_names!
    TaxonName.find_by_sql(
    ["SELECT t.* FROM taxon_names t 
    LEFT JOIN taxon_names g ON t.l > g.l AND t.r < g.r AND g.name = ?
    WHERE t.iczn_group = 'species' AND (#{self.sql_for_taxon_names('t', :public)})
    AND g.iczn_group = 'genus' AND g.id IS NOT NULL
    ORDER BY name", "#{genus}"])
  end
  
  # Repository-based
  def families_for_repository
    TaxonName.find_by_sql(
    ["SELECT p.*, count(*) as count FROM 
      (SELECT * FROM taxon_names t WHERE t.iczn_group = 'family' AND RIGHT(t.name,4) = 'idae') AS p
    LEFT JOIN 
      (SELECT id, l, r FROM taxon_names t2 WHERE t2.type_repository_id = ?) AS c 
    ON p.l < c.l AND p.r > c.r
    WHERE c.id IS NOT NULL 
    GROUP BY p.id ORDER BY name", self.default_institution_repository_id])
  end
  
  def letters_for_repository(family)
    TaxonName.find_by_sql(
    ["SELECT p.*, count(*) as count FROM 
      (SELECT t.l, t.r, LEFT(t.name,1) as letter FROM taxon_names t 
        LEFT JOIN taxon_names f ON t.l > f.l AND t.r < f.r AND f.name = ?
        WHERE t.iczn_group = 'genus' AND f.id IS NOT NULL
      ) AS p
    LEFT JOIN 
      (SELECT id, l, r FROM taxon_names t2 WHERE t2.type_repository_id = ?) AS c 
    ON p.l < c.l AND p.r > c.r
    WHERE c.id IS NOT NULL 
    GROUP BY p.letter ORDER BY p.letter", family, self.default_institution_repository_id])
  end
  
  def genera_for_repository(family, letter = "")
    TaxonName.find_by_sql(
    ["SELECT p.*, count(*) as count FROM 
      (SELECT t.* FROM taxon_names t 
        LEFT JOIN taxon_names f ON t.l > f.l AND t.r < f.r AND f.name = ?
        WHERE t.iczn_group = 'genus' AND t.name like ? AND f.id IS NOT NULL
      ) AS p
    LEFT JOIN 
      (SELECT id, l, r FROM taxon_names t2 WHERE t2.type_repository_id = ?) AS c 
    ON p.l < c.l AND p.r > c.r
    WHERE c.id IS NOT NULL 
    GROUP BY p.id ORDER BY name", family, "#{letter}%", self.default_institution_repository_id])
  end
  
  def species_for_repository(genus)
    TaxonName.find_by_sql(
    ["SELECT t.* FROM taxon_names t 
    LEFT JOIN taxon_names g ON t.l > g.l AND t.r < g.r AND g.name = ?
    WHERE t.iczn_group = 'species' AND t.type_repository_id = ?
    AND g.iczn_group = 'genus' AND g.id IS NOT NULL
    ORDER BY name", genus, self.default_institution_repository_id])
  end
  
  # Rebuilds the display_name
  def update_all_refs
    self.refs.each do |r|
      r.save
    end
  end

  # Could be abstracted in a much nicer way through AR, but right now SQL is *MUCH* faster
  def table_csv_string(options = {})
    opt = {
      :klass => nil,
      :header_row => true
    }.merge!(options)
    str = ''
 
    return false if !opt[:klass]

    klass_name = opt[:klass].name
    tbl = ActiveSupport::Inflector.tableize(opt[:klass].name.to_s)

    cols = []
    sql = ''

    if klass_name == "Person"  
      cols = %w(id last_name first_name middle_name login)
    else
      cols =  opt[:klass].columns.map(&:name) 
    end

    cols_str = cols.join(", ")

    case opt[:klass].name
    when "Person"
      sql = "SELECT #{cols_str} FROM people p INNER JOIN people_projs pp on p.id = pp.person_id WHERE pp.proj_id = #{self.id};"
    when "Ref"
      cols_str = cols.collect{|c| "r.#{c}"}.join(", ") # refs shared across projects, be more explicit for the join table
      sql = "SELECT #{cols_str} FROM refs r INNER JOIN projs_refs pr on r.id = pr.ref_id WHERE pr.proj_id = #{self.id};"
    when "TaxonName"
      sql = "SELECT #{cols_str} FROM taxon_names WHERE #{self.sql_for_taxon_names}"
    when "Author"
      sql = "SELECT #{cols_str} FROM authors a WHERE a.ref_id IN (SELECT r.id FROM refs r INNER JOIN projs_refs pr on r.id = pr.ref_id WHERE pr.proj_id = #{self.id})"
    when "ChrState"
      sql = "SELECT #{cols_str} FROM chr_states cs WHERE cs.chr_id IN (SELECT chrs.id from chrs WHERE chrs.proj_id = #{self.id})"  
    # when "Identifier"
    #  sql = "SELECT #{cols_str} FROM identifiers si WHERE si.specimen_id IN (SELECT specimens.id from specimens WHERE specimens.proj_id = #{self.id})"
    when "SpecimenDetermination"
      sql = "SELECT #{cols_str} FROM specimen_determinations sd WHERE sd.specimen_id IN (SELECT specimens.id from specimens WHERE specimens.proj_id = #{self.id})"

    else
      sql = "SELECT #{cols_str} FROM #{tbl}" 
    end

    # add the project level restrictions if they exist
    sql << " WHERE proj_id = #{self.id}" if opt[:klass].columns.collect{|c| c.name}.include?("proj_id")

    # build the str
    str << cols.join("\t") if opt[:header_row]# the header row
    str << "\n"

    ActiveRecord::Base.connection.select_rows(sql).each do |row| 
      # not filtering for tab characters here, likely should
      str << row.collect{|c| c == nil ? nil : c.gsub(/\n|\r\n|\r/, '\n')}.join("\t") + "\n"
    end
    str
  end

  # pass :excluded, or :included
  def ontology_restricted_ontology_classes(type)
    case type
    when :excluded
      return [] if self.ontology_exclusion_keyword.blank? || self.ontology_exclusion_keyword.tags.size == 0
      OntologyClass.tagged_with_keywords(:proj_id => self.id, :keywords => self.ontology_exclusion_keyword.tags.collect{|t| t.tagged_obj.class == Keyword ? t.tagged_obj : nil}.compact)
    when :included
      return [] if self.ontology_inclusion_keyword.blank? || (self.ontology_inclusion_keyword.tags.size == 0)
      OntologyClass.tagged_with_keywords(:proj_id => self.id, :keywords => self.ontology_inclusion_keyword.tags.collect{|t| t.tagged_obj.class == Keyword ? t.tagged_obj : nil}.compact)
    else
      []
    end
  end

   # pass :excluded, or :included
  def ontology_restrictor_keywords(type)
    case type
    when :excluded
      return [] if self.ontology_exclusion_keyword.blank?
        self.keywords.tagged_with(self.ontology_exclusion_keyword)
      OntologyClass.tagged_with_keywords(:proj_id => self.id, :keywords => self.ontology_exclusion_keyword.tags.collect{|t| t.tagged_obj.class == Keyword ? t.tagged_obj : nil}.compact)
    when :included
      return [] if self.ontology_inclusion_keyword.blank? 
        self.keywords.tagged_with(self.ontology_exclusion_keyword)
    else
      []
    end
  end

  # private

  # TODO: secure enough?  
  def nuke(nuker_id)
    if self.creator_id == nuker_id || Person.find(nuker_id).is_admin
      begin
        Proj.transaction do
          # deal with the HABTM
          self.people.clear
          self.refs.clear  
   
          self.destroy
        end
        return true
      rescue Exception => e
        # flash[:notice] = e.message 
      end
    end   
    false
  end

  # USE THIS WITH CAUTION.  TEST IT ON DEVELOPMENT DATA FIRST.  This has not been robustly tested for projects with diverse data.
  # This should work in many cases except where text strings are unique per project.  This problem is resolved for content_types but not 
  # for Keywords, Primers, synonymous Character or Matrix names etc.  In those case- rename the offending labels.
  # run this from script/console like: Proj.find(11).merge_to_project(:proj_id => 12, :postfix_otu_names => true, :postfix_chr_names => true, :person_id => 2) 
  # FK collisions *should* be detected and reported, fix, run again
  def merge_to_project(options = {})
    $merge = true 
    @opt = {
       :proj_id => nil,               
       :person_id => nil,
       :postfix_otu_names => false,
       :postfix_chr_names => false
    }.merge!(options.symbolize_keys)

    return false if !@opt[:proj_id] || !@opt[:person_id]
    return false if !@proj = Proj.find(@opt[:proj_id])
    return false if !@person = Person.find(@opt[:person_id])

    $proj_id = @proj.id 
    $person_id = @person.id

     begin
      Proj.transaction do 
        # try and do a little matching/transfer in a few cases (could also extend to Keywords)
        self.content_types.each do |o|
          if ct = ContentType.find(:first, :conditions => {:proj_id => @proj.id, :name => o.name})
            # update the templates 
            self.content_templates_content_types.each do |ctct|
              if ctct.content_type.name == ct.name
                ctct.content_type = ct
                ctct.save
              end
            end
            
            # update the content
            self.contents.each do |c|
              if c.content_type.name == ct.name
                c.content_type = ct
                c.save
              end
            end 

            # update the mapped_chr_groups
            self.chr_groups.each do |cg|
              if !cg.content_type.blank? && cg.content_type.name == ct.name
                cg.content_type = ct
                cg.save
              end
            end 
            # we have to only delete the merged object below
          end
        end

        self.genes.each do |g|
          if g = Gene.find(:first, :conditions => {:proj_id => @proj.id, :name => g.name})
              self.primers.each do |p|
                p.gene = g
                p.save
              end
              self.seqs.each do |s|
                s.gene = g
                s.save
              end
          end
        end

        # loop the remaining types
        [:has_many, :has_one, :has_and_belongs_to_many].each do |rel|
          Proj.reflect_on_all_associations(rel).collect{|o| o.name}.each do |r| # r is the class name  
            next if r == :text_content_types
            case r
            when :content_types 
              self.send(r).each do |o|
                if @ct = ContentType.find(:first, :conditions => {:proj_id => @proj.id, :name => o.name})
                  o.destroy 
                else
                  o.proj_id = @opt[:proj_id]
                  o.save
                end 
              end 
            
            when :genes
              self.send(r).each do |o|
                if @g = Gene.find(:first, :conditions => {:proj_id => @proj.id, :name => o.name})
                  o.destroy 
                else
                  o.proj_id = @opt[:proj_id]
                  o.save
                end 
              end 
       
            when :people
              # do nothing, these remain in the project to be deleted later, otherwise they get touched an pwds get borked

            else 
              t = self.send(r).each do |o|
                @o = o
                @r = r
                o.name = "#{o.name} [from: #{o.proj_id}]" if (@opt[:postfix_otu_names] && o.class == Otu) || (@opt[:postfix_chr_names] && o.class == Chr)
                o.proj_id = @opt[:proj_id]
                o.save
              end
            end
          end
        end # end rel types
      end # end transaction

    rescue Exception => e
      $merge = false
      raise  "#{e} o:(#{@o.to_yaml}) o_class: #{@o.class.to_s} r:(#{@r}) p:(#{@proj.id})"
    end
    $merge = false
    true
  end



end
