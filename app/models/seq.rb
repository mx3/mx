# == Schema Information
# Schema version: 20090930163041
#
# Table name: seqs
#
#  id                 :integer(4)      not null, primary key
#  gene_id            :integer(4)      not null
#  specimen_id        :integer(4)
#  type_of_voucher    :string(32)
#  otu_id             :integer(4)      not null
#  genbank_identifier :string(24)
#  ref_id             :integer(4)
#  sequence :text
#  attempt_complete   :boolean(1)
#  assigned_to        :string(64)
#  notes              :text
#  status             :string(32)
#  proj_id            :integer(4)      not null
#  creator_id         :integer(4)      not null
#  updator_id         :integer(4)      not null
#  updated_on         :timestamp       not null
#  created_on         :timestamp       not null
#

class Seq < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods


  SEQUENCE_REPORT_TYPES = {
    'Grid summary' => 'grid_summary',
    'Publication table' => 'publication_table',
    #     'GenBank submission file' => 'genbank_submission',
    'FASTA file' => 'fasta'
  }

  BIORUBY_TRANSLATION_TABLES = {
    1  => 'Standard (Eukaryote)',
    2  => 'Vertebrate Mitochondrial',
    3  => 'Yeast mitochondorial',
    4  => 'Mold, Protozoan, Coelenterate Mitochondrial and Mycoplasma/Spiroplasma',
    5  => 'Invertebrate Mitochondrial',
    6  => 'Ciliate Macronuclear and Dasycladacean',
    9  => 'Echinoderm Mitochondrial',
    10 => 'Euplotid Nuclear',
    11 => 'Bacteria',
    12 => 'Alternative Yeast Nuclear',
    13 => 'Ascidian Mitochondrial',
    14 => 'Flatworm Mitochondrial',
    15 => 'Blepharisma Macronuclear',
    16 => 'Chlorophycean Mitochondrial',
    21 => 'Trematode Mitochondrial',
    22 => 'Scenedesmus obliquus mitochondrial',
    23 => 'Thraustochytrium Mitochondrial Code'
  }


  belongs_to :pcr
  belongs_to :gene
  belongs_to :otu
  belongs_to :ref 
  belongs_to :specimen
   
  scope :with_fragment, lambda {|*args| {:conditions => ['sequence LIKE ? OR sequence LIKE ? OR sequence LIKE ?', (args.first ? "%#{args.first}%" : -1), (args.first ? "#{args.first}%" : -1),(args.first ? "%#{args.first}" : -1)]}} 
  scope :with_nucleotides, lambda {|*args| {:conditions => ['length(sequence) > 0']}}

  validate :check_record
  def check_record
    # if pcr_id is present then no specimen, OTU or Gene is allowed (pcr_id is tied to extract_id etc.)
    if !pcr.blank? && (!otu.blank? || !gene.blank? || !specimen.blank?)
      errors.add(:pcr_id, ' if PCR is provided then gene, OTU and specimen can not be present')
    end
  
    # if OTU is present gene must be present 
    if !otu.blank? && gene.blank?
      errors.add(:gene_id, ' if OTU is provided gene must be present')
    end

    # if gene is present OTU or specimen must also be present (alternately gene is tracked through Pcr) # TODO: modify for specimen
    if !gene.blank? && otu.blank? && specimen.blank?
      errors.add(:otu_id, ' if gene is provided OTU or specimen must be present')
    end

    # ensure Sequence is present for attempt to be complete  TODO: validate on update?
    errors.add(:sequence, ' sequence not complete if no seqeuence string present') if attempt_complete? && (!sequence.blank?)

    # ensure a minimal valid combination of data is added 
    if !sequence.blank? && otu.blank? && specimen.blank? && gene.blank? && pcr.blank?
      errors.add(:otu_id, ' must supply PCR alone OR OTU and gene')
    end

    # requirement DEPRECATED
    # At present OTU/gene combinations must be unique when specimen_id is absent 
    # if Seq.find(:first, :conditions => ["otu_id = (?) and gene_id = (?)", otu_id, gene_id])
    #   errors.add(" sequence for otu_id is already present")
    # end
  end

  # TODO: needs work!
  def display_name(options = {})
    opt = {
      :type => nil 
    }.merge!(options.symbolize_keys)

    s = ''

    case opt[:type]
    when :selected
    else
      if self.gene_id.blank? # then it must be PCR based
        s << self.pcr.display_name
      else 
        s << Gene.find(gene_id).name + " " + Otu.find(otu_id).display_name
      end
    end
  end

  def chromatograms
    if pcr
      self.pcr.chromatograms
    else
      []
    end
  end

  def bound_otus # :yields: Array, containing all OTUs bound to this sequence (typically there is only 1, but many is possible given the model)
    # The Seqs table is general purpose allowing for metadata at various levels to be recorded, depending on the workflow etc.
    # Given this a Seq may reference Otus via various relationships.
    otus = []
    
    # explicitly bound
    otus += [self.otu] if self.otu

    # bound through specimens
    tmp_otu = self.specimen.most_recent_otu_determination if self.specimen
    otus += [tmp_otu] if tmp_otu

    # bound through PCRs
    tmp_otu = self.pcr.otu if self.pcr && self.pcr.otu
    otus += [tmp_otu] if tmp_otu

    otus.uniq
  end

  def source_specimen # :yields: Specimen | nil (specimen is referenced through Seq | Extract)
    return nil if !self.pcr && !self.specimen
    if pcr
      self.pcr.extract.specimen
    elsif self.specimen
      self.specimen
    else
      nil
    end
  end

  def bound_genes # :yields: Array [Gene(s)] referenced through Seq#pcr or Seq#gene
    if !gene && pcr.blank?
      nil
    elsif !pcr.blank?
      [pcr.fwd_primer.gene, pcr.rev_primer.gene].uniq
    elsif !gene.blank?
      [gene]
    else 
      nil
    end
  end

  def has_material # :yields: String, indicating the amount of dna_usuable materal in this project
    @s_lots = Lot.with_usable_dna.with_value_specimens.determined_as_otu(otu_id).inject(0){|sum, l| sum += l.value_specimens}
    @s_spec = Specimen.with_usable_dna.determined_as_otu(otu_id).count
    "lots: #{@s_lots.to_s}, specimens: #{@s_spec.to_s}"
  end
 
  def self.create_multiple(options = {})
    @opt = {
      :otu_group_id => nil,
      :gene_id => nil
    }.merge!(options.to_options)

    return false if !@opt[:otu_group_id] || ! @opt[:gene_id]
 
    otus = OtuGroup.find(@opt[:otu_group_id]).otus
    @p = 0
    @f = 0
  
    @failed = []  
    for otu in otus
      @seq = Seq.new(:otu_id => otu.id, :gene_id => @opt[:gene_id])

      if @seq.save
        @p += 1
      else
        @failed << @seq
        @f += 1
      end  
    end 
    
    return [@p, @f]
  end

  # lots of redundancy here, could simplify
  # TODO: use bioruby
  def self.fasta_file(options = {})
    @opt = {
      :all_otus => false,
      :proj_id => nil,
      :otu_group_id => nil,
      :gene_group_id => nil,
      :data_only => false
    }.merge!(options.to_options)
    
    f = ''
 
    return false if (!@opt[:all_otus] && !@opt[:otu_group_id]) || !@opt[:gene_group_id] || !@opt[:proj_id] 

    if @opt[:all_otus] 
      @otus = Proj.find(@opt[:proj_id]).otus
    else
      @otugroup = OtuGroup.find(@opt[:otu_group_id])
      @otus = @otugroup.otus 
    end

    @genegroup = GeneGroup.find(@opt[:gene_group_id])
    @genes = @genegroup.genes

    max_otu_strlen = @otus.collect{|o| o.display_name(:type => :matrix_name).length}.max # length longest OTU name
    max_otu_id = @otus.collect{|o| o.id.to_s.length}.max
    
    # return only otus with sequences initiated if checked
    if (@opt[:data_only])
      @s = "seqs.gene_id = " +  @genes.collect{|o| o.id}.join(' OR seqs.gene_id = ')
      @otus = (@otus & Otu.find_by_sql("SELECT otus.* from otus INNER JOIN seqs ON otus.id = seqs.otu_id WHERE ( (otus.proj_id = #{@opt[:proj_id]}) AND (#{@s}));")  )
    end

    f = ''
    for gene in @genes 
      for otu in @otus
        f <<  ">mx" + "0"*(max_otu_id - otu.id.to_s.length) + "#{otu.id.to_s}_#{otu.display_name(:type => :matrix_name)}" + " "*(max_otu_strlen + 1 - otu.display_name(:type => :matrix_name).length)
        f << " [#{gene.name}"
        @seq = Seq.find_by_gene_id_and_otu_id(gene.id, otu.id)
        if @seq and @seq.sequence.to_s.length > 0
          f << "_mxid_#{@seq.id}]\n"
          f << "#{@seq.sequence}\n"
        else
          f << "]\n"

        end
        f << "\n"
      end
      f << "\n"
    end
    f
  end

  def self.one_line_file(options = {})
    @opt = {
      :all_otus => false,
      :proj_id => nil,
      :otu_group_id => nil,
      :gene_group_id => nil,
      :data_only => false

    }.merge!(options.to_options)
    
    f = ''
 
    return false if (!@opt[:all_otus] && !@opt[:otu_group_id]) || !@opt[:gene_group_id] || !@opt[:proj_id] 

    if @opt[:all_otus] 
      @otus = Proj.find(@opt[:proj_id]).otus
    else
      @otugroup = OtuGroup.find(@opt[:otu_group_id])
      @otus = @otugroup.otus 
    end

    @genegroup = GeneGroup.find(@opt[:gene_group_id])
    @genes = @genegroup.genes

    # return only otus with sequences initiated if checked
    if (@opt[:data_only])
      @s = "seqs.gene_id = " +  @genes.collect{|o| o.id}.join(' OR seqs.gene_id = ')
      @otus = (@otus & Otu.find_by_sql("SELECT otus.* from otus INNER JOIN seqs ON otus.id = seqs.otu_id WHERE ( (otus.proj_id = #{@opt[:proj_id]}) AND (#{@s}));")  )
    end
    
    max_otu_strlen = @otus.collect{|o| o.display_name(:type => :matrix_name).length}.max # length longest OTU name
    max_otu_id = @otus.collect{|o| o.id.to_s.length}.max
    
    f = '['
    f << "OTU group: #{@otugroup.name}," if !@opt[:all_otus]
    f << " Genes: " + @genes.collect{|o| o.name}.join(" | ") + "]\n\n"

    for otu in @otus
      
      f <<  "mx" + "0"*(max_otu_id - otu.id.to_s.length) + "#{otu.id.to_s}_#{otu.display_name(:type => :matrix_name)}" + " "*(max_otu_strlen + 1 - otu.display_name(:type => :matrix_name).length)

      for gene in @genes 
        @seq = Seq.find_by_gene_id_and_otu_id( gene.id, otu.id)
        if @seq and @seq.sequence.to_s.length > 0
          f << " #{@seq.sequence}"
        else
          f << " ---"
        end
      end
      f << "\n"
    end
    f
  end


  def self.nexus_file(options = {})
    @opt = {
      :all_otus => false,
      :proj_id => nil,
      :otu_group_id => nil,
      :gene_group_id => nil,
      :data_only => false

    }.merge!(options.to_options)
    
    f = ''

    return false if (!@opt[:all_otus] && !@opt[:otu_group_id]) || !@opt[:gene_group_id] || !@opt[:proj_id] 

    if @opt[:all_otus] 
      @otus = Proj.find(@opt[:proj_id]).otus
    else
      @otugroup = OtuGroup.find(@opt[:otu_group_id])
      @otus = @otugroup.otus 
    end

    @genegroup = GeneGroup.find(@opt[:gene_group_id])
    @genes = @genegroup.genes

    # return only otus with sequences initiated if checked
    if (@opt[:data_only])
      @s = "seqs.gene_id = " +  @genes.collect{|o| o.id}.join(' OR seqs.gene_id = ')
      @otus = (@otus & Otu.find_by_sql("SELECT otus.* from otus INNER JOIN seqs ON otus.id = seqs.otu_id WHERE ( (otus.proj_id = #{@opt[:proj_id]}) AND (#{@s}));")  )
    end

    max_otu_strlen = @otus.collect{|o| o.display_name(:type => :matrix_name).length}.max # length longest OTU name
    max_gene_strlen = []
    total_strlen = 0
    max_otu_id = @otus.collect{|o| o.id.to_s.length}.max
    
    # find length of each seq
    for gene in @genes
      max_len = 0
      for otu in @otus
        if @s = Seq.find_by_gene_id_and_otu_id(gene.id, otu.id)
          (@s.sequence.to_s.length > max_len) and (max_len = @s.sequence.to_s.length)
        end
      end
      max_len == 0 and max_len = 1 # in case an interleave is completely empty, give it a character so paup doesn't barf
      max_gene_strlen[gene.id] = max_len;
      total_strlen += max_len
    end
       
    f = "#NEXUS\n\n[generated by mx on #{Time.now}]\n"
    f << "["
    f << "OTU group: #{@otugroup.name}," if !@opt[:all_otus]
    f << " Genes: " + @genes.collect{|o| o.name}.join(" | ") + "]\n\n"
    
    f << "Begin data;\n\n"
    f << "Dimensions\n";
    f << "   ntax = #{@otus.length}\n   nchar = #{total_strlen};\n"
    f << "Format\n   data = DNA\n   missing = ?\n   gap = -\n"
    @genes.length > 1 and f << "interleave\n"
    f << ";\n"
    f << "Matrix\n"
    
    for gene in @genes   
      f << "\n[ Gene: #{gene.display_name} #{max_gene_strlen[gene.id]} ]\n"

      for otu in @otus
        f <<  "mx" + "0"*(max_otu_id - otu.id.to_s.length) + "#{otu.id.to_s}_#{otu.display_name(:type => :matrix_name)}" + " "*(max_otu_strlen + 1 - otu.display_name(:type => :matrix_name).length)

        @seq = Seq.find_by_gene_id_and_otu_id( gene.id, otu.id)
        if @seq and @seq.sequence.to_s.length > 0
          f << "#{@seq.sequence}" +  '-'*(max_gene_strlen[gene.id] - @seq.sequence.length)
        else
          f << "?"*max_gene_strlen[gene.id]
        end
        f << "   [mxid_#{@seq.id}]\n" if @seq
      end
      f << "\n"
    end
    f << ";\nend;\n"
    f
  end

  # returns an array of arrays in format [[Pcr||nil, Bio::Seq]...]
  def self.batch_load_FASTA(options = {})
    opt = {
      :file => nil,         # a File (not String!) 
      :gene => nil,         # stub
      :otu => nil,          # stub
      :pcr_by_id => true,   # assumes the last _id in the description is a mx pcr_id
    }.merge!(options.symbolize_keys)

    return nil if !opt[:file]

    seqs = []

    begin 
      ff = Bio::FlatFile.auto(opt[:file])
      ff.each_entry do |seq|
        foo = seq.definition.split("_")
        next if foo == []
        if pcr = Pcr.find(:first, :conditions => {:id => foo.last})
          seqs << [Seq.new(:pcr => pcr, :sequence => seq.seq), seq]
        else
          seqs << [nil, seq]
        end
      end
      return nil if seqs.size == 0
    rescue
      return nil
    end
    seqs
  end

  def self.add_FASTA_after_verify(params)
    seqs = []
    begin
      Seq.transaction do |t|
        params['seq'].keys.each do |s| # the selected seqs
          if params['seq'][s] == "1"
            s = Seq.new(params['seqs'][s])
            s.save!
            seqs.push(s)
          end
        end
      end
    rescue
      return false
    end
    return seqs 
  end

  def self.summary_grid(options = {}) # :yields: Hash {:otus => [], :genes => []} 
    opt = {}.merge!(options)
    result = {}

    otu_group = nil
    otu = nil
    gene = nil
    gene_groups = nil

    otus = []
    genes = []

    # gather OTUs
    otu_group = OtuGroup.find(opt['otu_group_id']) if !opt['otu_group_id'].blank?
    otus += otu_group.otus if otu_group

    otu = Otu.find(opt['otu_id']) if !opt['otu_id'].blank?
    otus += [otu] if otu

    # gather genes
    gene_group = GeneGroup.find(opt['gene_group_id']) if !opt['gene_group_id'].blank?
    genes += gene_group.genes if gene_group

    gene = Gene.find(opt['gene_id']) if !opt['gene_id'].blank?
    genes += [gene] if gene

    result.merge!(:otus => otus)
    result.merge!(:genes => genes) 

    # return only otus with sequences initiated if checked
    #if (opt[:view][:data_only] == '1')
    #   s = "seqs.gene_id = " +  @genes.collect{|o| o.id}.join(' OR seqs.gene_id = ')
    #   @otus = (@otus & Otu.find_by_sql("SELECT otus.* from otus JOIN seqs ON otus.id = seqs.otu_id WHERE ((otus.proj_id = #{opt[:proj_id]}) AND (#{s}));")  )
    #end
    if result[:otus].empty? || result[:genes].empty? 
      return false
    end

    result
  end

  def self.find_for_auto_complete(string, proj_id)
    value = string.split.join('%') # hmm... perhaps should make this order-independent

    lim = case string.length
    when 1..2 then  10
    when 3..4 then  25
    else lim = false # no limits
    end 

    Seq.find(:all, :conditions => ["(t.name LIKE ? OR o.name LIKE ? OR seqs.id = ? OR sequence LIKE ? OR seqs.id = ?) AND seqs.proj_id = ?", "%#{value}%", "%#{value}%", value.gsub(/\%/, ""), "%#{value}%", value,  proj_id, ],
      :order => "seqs.id",
      :limit => lim,
      :joins => 'LEFT OUTER JOIN otus o on seqs.otu_id = o.id LEFT OUTER JOIN taxon_names t on o.taxon_name_id = t.id')
  end


end
