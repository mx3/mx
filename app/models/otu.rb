# == Schema Information
# Schema version: 20090930163041
#
# Table name: otus
#
#  id               :integer(4)      not null, primary key
#  taxon_name_id    :integer(4)
#  is_child         :boolean(1)
#  name             :string(255)
#  manuscript_name  :string(255)
#  matrix_name      :string(64)
#  parent_otu_id    :integer(4)
#  as_cited_in      :integer(4)
#  revision_history :text
#  iczn_group       :string(32)
#  syn_with_otu_id  :integer(4)
#  sensu            :string(255)
#  notes            :text
#  proj_id          :integer(4)      not null
#  creator_id       :integer(4)      not null
#  updator_id       :integer(4)      not null
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null

class Otu < ActiveRecord::Base
  has_standard_fields
  # has_pulse

  include ModelExtensions::Taggable
  # Otus are not directly figurable ... yet
  include ModelExtensions::DefaultNamedScopes # default_scopes'
  include ModelExtensions::MiscMethods

  has_many :association_parts, :dependent => :destroy # need to change this to a through relationship
  has_many :associations, :through => :association_parts
  has_many :claves, :class_name => "Clave", :dependent => :nullify
  has_many :codings, :dependent => :destroy
  has_many :chrs, :through => :codings
  has_many :contents, :dependent => :destroy # this is both public and "private" versions
  has_many :content_types, :through => :contents, :uniq => true
  has_many :distributions, :dependent => :destroy
  has_many :geogs, :through => :distributions
  has_many :image_descriptions, :dependent => :destroy
  has_many :immediate_child_synonymous_otus, :class_name => "Otu", :foreign_key => "syn_with_otu_id", :dependent => :nullify
  has_many :lots, :dependent => :destroy
  has_many :ipt_records, :dependent => :nullify
  has_many :seqs, :dependent => :destroy
  has_many :specimen_determinations, :dependent => :destroy
  has_many :specimens, :through => :specimen_determinations
  has_many :mxes_otus
  has_many :mxes, :through => :mxes_otus, :order => 'mxes.name'
  has_many :otu_groups_otus, :dependent => :destroy
  has_many :otu_groups, :through => :otu_groups_otus, :source => :otu_group, :order => 'otu_groups.name'

  belongs_to :parent_otu, :class_name => "Otu", :foreign_key => "parent_otu_id"
  belongs_to :ref, :foreign_key => "as_cited_in"
  belongs_to :sensu_ref, :class_name => "Ref", :foreign_key => "sensu_ref_id"
  belongs_to :syn_otu, :class_name => "Otu", :foreign_key => "syn_with_otu_id"
  belongs_to :taxon_name

  # Careful- Otu.in_matrix_range will return Otus from different matrices, use as Mx#otus#in_mx_position
  # starts at 1!!
  # TODO: Resolve _with_ vs. _by_, with should be present _by_ should be search?
  scope :with_taxon_name, lambda {|*args| {:conditions => ['otus.taxon_name_id = ?', (args.first || -1)]}}
  scope :with_taxon_name_populated, :conditions => 'otus.taxon_name_id IS NOT NULL'
  scope :within_mx_range, lambda {|*args| {:include => :mxes_otus, :conditions => ["mxes_otus.position >= ? AND mxes_otus.position <= ?", (args.first || -1), (args[1] || -1)]}}
  scope :with_seqs_not_through_specimens, lambda {|*args| {:include => :seqs, :conditions => "otus.id IN (SELECT otu_id from seqs)"}}

  # use in_proj from /lib/default_named_scopes
  # scope :in_project, lambda {|proj| where(:proj_id => proj.id) }

  scope :with_otu_group, lambda {|id_or_rec|
      id_or_rec = id_or_rec.id if (id_or_rec.is_a?(ActiveRecord::Base))
      joins(:otu_groups_otus).where('otu_groups_otus.otu_group_id' => id_or_rec)
    }

  # TODO: mx3 following two scopes untested
  scope :with_seqs_through_specimens, lambda {|*args| {:include => [:specimen_deteriminations, :specimens, :extracts, :seqs], :conditions => "otus.id IN (SELECT otu_id from seqs)"}}
  scope :with_seqs_through_extracts, lambda {|*args| {:include => [:specimen_deteriminations, :specimens, :extracts, :seqs], :conditions => "otus.id IN (SELECT otu_id from seqs)"}}

  # NOTE: the 'scope :with_content, joins(:contents).includes(:taxon_name)'
  #  version presently throws the Marshall, Mutex error. Who knows why. Other scopes appear to work fine.
  #  Possible leads on debugging: look at 1) #method_missing code, 2) the alchemist gem, 3) session stores, 4) some content reserved word
  #  The non-suggary version here works
  def self.with_content
    joins(:contents).includes(:taxon_name).group(:id)
  end

  scope :with_published_content, joins(:taxon_name).where('otus.id IN (SELECT otu_id FROM contents WHERE pub_content_id IS NOT NULL)')
  scope :in_otu_group,  lambda {|*args| {:include => :otu_groups_otus, :conditions =>  ["otus.id in (SELECT otu_id from otu_groups_otus WHERE otu_group_id = ?)", (args.first || -1)]}}
  scope :ordered_taxonomically, {:include => [:taxon_name], :order => 'taxon_names.l, otus.name, otus.matrix_name'}
  scope :with_public_content_for_template, lambda {|*args| {:include => :contents, :join => 'public_contents.content_type_id on public_contents.content_type_id = contents.content_type_id',  :conditions => ["otus.id IN (SELECT otu_id from public_contents) AND contents.content_type_id not null"]}}

  # TODO: before_save filter to update non normalized Codings fields

  before_destroy :check_image_descriptions
  def check_image_descriptions
    raise 'Unable to delete OTU, there are attached image descriptions.' if self.image_descriptions.length > 0
  end

  validate :check_record
  def check_record
    if matrix_name =~ /\W/
      errors.add(:mx_name, "can not contain whitespace")
    end

    # synonymy
    # TODO: need to add check for circularity
    if (syn_with_otu_id == self.id) && !self.id.nil?
      errors.add(:syn_with_otu_id, "can not be synonymous with self")
    end
  end

  def display_name(options = {})
    opt = {
      :type => :line, # :list, :head, :select, :sub_select, :selected
      :target => ""
    }.merge!(options.symbolize_keys)

    xml = Builder::XmlMarkup.new(:indent=> 2, :target => opt[:target])

    case opt[:type]
    when :selected # TODO as it appears after selection (non-ajax?, no css)
      if taxon_name
        xml << taxon_name.display_name(:type => :selected)
      else
        xml <<  name
      end
    when :list
      self.display_name(:target => xml, :type => :multi_name) # awesome, builds right on
    when :multi_name
      xml.span("class" => "otu_taxon_name") {|t| taxon_name.display_name(:type => :fancy_name, :target => t) } if taxon_name
      xml.span(name, "class" => "otu_name") if name?
      xml.span(manuscript_name, "class" => "otu_manuscript_name") if manuscript_name?
      xml.span(matrix_name, "class" => "otu_matrix_name") if matrix_name?
    when :dual_name # TODO: deprecate
      xml.span("class" => "otu_taxon_name") {|t| taxon_name.display_name(:target => t)} if taxon_name
      xml << " / " if !taxon_name.blank? && !name.blank?
      xml.span(name, 'class' => 'otu_name') if name?
    when :matrix_name
      return matrix_name if not matrix_name.to_s.length < 1 # not matrix_name.to_s.length < 1
      return name.gsub(/[^\w]/, "_") if not name.to_s.length < 1 ## concievably add id and truncate here to ensure uniqueness
      return taxon_name.display_name(:type => :string_no_author_year).gsub(/[^\w^\<^\>^\/]/, "_") if taxon_name
      return "mx_otu_id_#{self.id}"
    when :taxon_name # no markup here
      if self.taxon_name
        xml << self.taxon_name.display_name(:type => :for_select)
      else
        xml << 'no taxon name tied to this OTU'
      end
    else
      # the priority logic is that if you provide an OTU name that name superseeds the TaxonName.  If you mean the TaxonName blank self.name.
      xml << [self.name, (self.taxon_name ? self.taxon_name.display_name(:type => :name_with_author_year) : nil), self.matrix_name, self.manuscript_name].reject{|k| k.nil? || k == ""}.first.to_s
    end
    opt[:target].html_safe
  end

  # TODO: verify, and perhaps move to has_many
  def images_from_codings
    codings.inject([]){|sum, c| sum += c.figures.andand.collect{|f| f.images}}.uniq
  end

  def images_from_specimens
    specimens_most_recently_determined_as.inject([]){|sum, s| sum += s.images}.uniq
  end

  def top_syn(syn) # :yields: Otu | nil
    return nil if syn.nil?
    o = Otu.find(syn)
    if o.syn_otu
      top_syn(o.syn_otu.id)
    else
      o
    end
  end

  def mb_image_descriptions
    ImageDescription.find_by_sql(["Select * from image_descriptions id left join images i on id.image_id = i.id WHERE i.mb_id is not null and id.otu_id = ?;", self.id])
  end

  def has_image_of_mb_id(mb_id)
    ImageDescription.find_by_sql(["SELECT * from image_descriptions id left join images i on id.image_id = i.id WHERE id.otu_id = ? AND i.mb_id = ?;", self.id, mb_id])
  end

  def move_images_to_otu(to_otu_id)
    o = Otu.find(to_otu_id) or return false
    # (self.proj_id)
    self.image_descriptions.each do |i|
      i.otu_id = o.id
      i.save!
    end
    true
  end

  # updates the otu_id of the many side to of current records to the passed Otu
  # has_many_rel is a model name, as a string
  def transfer_has_manys_to_otu(otu, has_many_rel)
    return false if self.id == otu.id # can't transfer to yourself
    self.send(has_many_rel).each do |o|
      o.otu_id = otu.id
      o.save
    end
  end

  # appends all the content to the provided Otu, :del => true will delete the old conten
  def transfer_content_to_otu(otu, delete_from_incoming = false)
    return false if self.id == otu.id # can't transfer to yourself
    self.contents.each do |c|
      c.transfer_to_otu(otu)
    end
    true
  end

  def publish_all_content
    self.contents.that_are_publishable.each do |c|
      c.publish
    end
  end

  # :section: Matrix related methods

  def codings_by_chr(chr_group_id = nil)
    if chr_group_id
      chrs = Chr.find_by_sql ["SELECT chrs.* FROM chrs LEFT JOIN chr_groups_chrs ON chrs.id = chr_groups_chrs.chr_id LEFT JOIN codings ON chrs.id = codings.chr_id WHERE codings.otu_id = ? AND codings.id IS NOT NULL AND chr_groups_chrs.chr_group_id = ?", id, chr_group_id]
    else
      chrs = Chr.find_by_sql ["SELECT chrs.* FROM chrs LEFT JOIN codings ON chrs.id = codings.chr_id WHERE codings.otu_id = ? AND codings.id IS NOT NULL", id]
    end
    foobar = Hash.new
    # for each chr, set it as a key. then set the array of corresponding codings as the value
    for chr in chrs
      foobar[chr] = codings.select {|c| c.chr_id == chr.id}
    end
    foobar
  end

  # returns all Characters for which the Otu is uniquely coded for (across all codings) --- needs a better name
  def unique_codings_by_chr
    @chars = []
    for c in self.codings
      (@chars << [ Chr.find(c.chr_id), ChrState.find(c.chr_state_id)]) if c.similarly_coded_otus.size == 1
    end
    @chars
  end

  # TODO: DEPRECATED
  # returns all Codings that represent "diagnostic" states
  def unique_codings
    Coding.find_by_sql(["Select codings.*, count(chr_state_id) as cnt from codings group by chr_state_id having cnt = 1 and otu_id = ?;", self.id])
  end

  # return all char_state_ids for a given matrix
  def chr_states_by_mx(mx_id)
    mx = Mx.find(mx_id) or throw "can't find the matrix in Otu.chr_states_by_mx"
    sql = mx.chrs.inject([]) {|sum, c| sum + c.chr_states.collect{|o| o.id}}.inject([]){|s, o| s << "chr_state_id = #{o}"}.join(' OR ')
    Coding.find(:all, :conditions => "(#{sql}) AND otu_id = #{self.id}").collect{|o| o.chr_state_id}
  end

  # as unique_codings, but returns an Array of chr_state ids
  def unique_states
    Coding.find_by_sql(["SELECT otu_id, chr_state_id, count(chr_state_id) as cnt FROM codings GROUP BY chr_state_id HAVING cnt = 1 and otu_id = ?", self.id]).collect{|o| o.chr_state_id.to_i}
  end

  # :section: Methods with project wide application

  def all_synonymous_otus(already_collected = []) # :yields: Array of Otus synonymous with this one
    # use already_collected to prevent loops
    return already_collected if already_collected.detect { |e| e == self }
    syns = immediate_child_synonymous_otus
    syns.map { |s| s.all_synonymous_otus(syns) }.flatten
  end

  # :section: DNA related methods

  def extracts
    (Extract.from_specimens_determined_as_otu(self) + Extract.from_lots_determined_as_otu(self)).uniq # shouldn't need uniq or Lot ultimately
  end

  def pcrs_by_gene(gene)
    gene.pcrs & self.pcrs # hmm - slow
  end

  def pcrs
    self.extracts.inject([]){|sum, e| sum += e.pcrs}.flatten
  end

  def sequences(options = {}) # :yields: Array of [Seq]
    opt = {
      :report => :all,  # :all, :seqs, :extracts
      :gene_ids => []
    }.merge!(options)

    genes = []
    genes = Gene.find(opt[:gene_ids]) if opt[:gene_ids].size > 0
    all_seqs = self.extracts.inject([]){|sum, e| sum += e.seqs}.flatten + self.seqs
    all_seqs.uniq!
    seqs = []

    case opt[:report]
    when :all
      if genes.size > 0
        all_seqs.each do |s|
          if !(genes & s.bound_genes).empty? # at least one gene matches
            seqs << s
          end
        end
      else
        seqs = all_seqs
      end

    when :seqs # redundant option with self.seqs, kept for completeness
      if genes.size > 0

      else
        seqs = self.seqs
      end
    when :extracts
      if genes.size > 0

      else
        seqs = self.extracts.inject([]){|sum, e| sum += e.seqs}.flatten
      end

    end
    seqs.uniq
  end

  # Somewhat deprecated
  def extract_summary
    meta = {'attempted' => 0, 'genes_attempted' => '', 'quality' => '', 'available_specimens' => 0, 'chromatograms_attempted' => ''}

    @specimens = Specimen.with_usable_dna.determined_as_otu(self)
    @lots = self.lots.with_usable_dna
    @extracts = self.extracts

    @genes_tagged_to_seqs = Proj.find(self.proj_id).genes.used_in_seqs_from_otu(self)
    @chromatograms = []

    # this needs to be simplified somehow, like Otu.chromatograms
    @extracts.each do |extract|
      @chromatograms += extract.pcrs.collect{|o| o.chromatograms}
    end

    meta['available_specimens'] = @specimens.size + @lots.collect{|o| o.value_specimens}.inject(0) { |n, value| n + value }
    meta['attempted'] = @extracts.size
    meta['quality'] = (@extracts.size > 0) ? @extracts.collect{|o| o.quality}.join("; ") : "<i>no extracts</i>"
    meta['genes_attempted'] =  @genes_tagged_to_seqs.size > 0 ? @genes_tagged_to_seqs.collect{|o| o.name}.join("; ") : ""
    meta['chromatograms_attempted'] = @chromatograms.size
    meta
  end

  # :section: Content specific methods

  # scopes here?
  # returns a hash with the ContentType id pointing to the Content
  def text_content
    Content.that_are_publishable.by_otu(self).inject({}){|hash, c| hash.update(c.content_type_id => c)} # note there shouldn't be 2 private contents of the same type for the same OTU, if there is "bad things"
  end

  def has_public_content?
    return true if Content.by_otu(self).that_are_published.size > 0
    false
  end

  # :section: Image related methods

  def images # :yields: Array of Images (not ImageDescriptions)
    [self.image_descriptions(self.proj_id).collect{|id| id.image}, self.images_from_codings, self.images_from_specimens].flatten.uniq
  end

  # :section: Specimen/Ce methods

  def specimens_most_recently_determined_as # :yields: Array of Specimens whose most recent determination is self
    Specimen.with_current_determination(self)
  end

  def specimens_of_status(type)
    self.specimens_most_recently_determined_as
  end

  def markers_for_currently_determined_specimens
    self.specimens_most_recently_determined_as.that_are_mappable.inject([]){|ary, s| ary << s.ce.gmap_hash.update({:specimen => s.display_name(:type => :identifiers)}) }
  end

  def self.find_for_auto_complete(value)
    # TODO: pass proj_id
    value.downcase!
    find_by_sql(["SELECT o.* FROM otus AS o
      LEFT JOIN taxon_names t ON o.taxon_name_id = t.id
      WHERE o.proj_id = #{$proj_id} AND (
        (t.cached_display_name LIKE ?) OR
        (o.manuscript_name LIKE ?) OR
        (o.name LIKE ?) OR
        (o.matrix_name LIKE ?) OR
        (o.id = ?)
      );",
        "%#{value}%", "%#{value}%", "%#{value}%", "#{value}%", value.gsub(/.[\D\s]/, '') ])
  end

  ## Recursive addition of Otus from a TaxonName
  def self._create_r(options = {})
    # requires :proj_id, :otu => {}, :include_children, optional - :otu_group_id
    return false if options[:proj_id].blank?

    # ICZN group defaults to the group of the taxon name, if present
    if !options[:otu][:taxon_name_id].blank?
      tn = TaxonName.find(options[:otu][:taxon_name_id])
      options[:otu][:iczn_group] = tn.iczn_group if options[:otu][:iczn_group].blank?
    end

    @otu = Otu.new(options[:otu])
    @otu.proj_id = options[:proj_id]
    return false unless @otu.save

    if !options[:otu_group_id].blank?
      if not @otu.otu_groups <<  OtuGroup.find(options[:otu_group_id])
        flash[:notice] = 'Failed to add OTU to group.'
        return false
      end
    end

    if !options[:otu][:taxon_name_id].blank? && options[:include_children]
      children = tn.children
      for child in children
        # you can manually add the same taxon_name to your otu list
        # twice, but in recursive mode duplicates are not added
        next if Otu.find(:first, :conditions => "taxon_name_id = #{child.id} AND proj_id = #{options[:proj_id]}")
        options[:otu][:taxon_name_id] = child.id
        return false unless Otu._create_r(:otu => options[:otu],
          :include_children => options[:include_children],
          :proj_id => options[:proj_id],
          :otu_group_id => options[:otu_group_id])
      end
    end
    return @otu.id # true return the id of the last OTU created
  end

end
