# == Schema Information
# Schema version: 20090930163041
#
# Table name: extracts
#
#  id                       :integer(4)      not null, primary key
#  lot_id                   :integer(4)
#  specimen_id              :integer(4)
#  protocol_id              :integer(4)
#  parts_extracted_from     :text
#  quality                  :string(12)
#  notes                    :text
#  extracted_on             :date
#  extracted_by             :string(128)
#  other_extract_identifier :string(128)
#  proj_id                  :integer(4)      not null
#  creator_id               :integer(4)      not null
#  updator_id               :integer(4)      not null
#  updated_on               :timestamp       not null
#  created_on               :timestamp       not null
#

class Extract < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  belongs_to :lot
  belongs_to :specimen
  belongs_to :protocol

  has_many :pcrs, :dependent => :destroy # in DB context they are as good as gone
  has_many :genes, :through => :pcrs
  has_many :status_levels, :class_name => 'ExtractsGene'
  has_many :seqs, :through => :pcrs 

  scope :from_specimen, lambda {|*args| {:conditions => ["specimen_id = ?", (args.first || -1)] }}
  scope :from_lot, lambda {|*args| {:conditions => ["lot_id = ?", (args.first || -1)] }}
  scope :from_specimens_determined_as_otu, lambda {|*args| {:conditions => ["specimen_id IN (SELECT specimen_id from specimen_determinations WHERE otu_id = ?)", (args.first || -1)] }}
  scope :from_lots_determined_as_otu, lambda {|*args| {:conditions => ["lot_id IN (SELECT id FROM lots WHERE otu_id = ?)", (args.first || -1)] }}
  scope :recently_changed, lambda {|*args| {:conditions => ["(extracts.created_on > ?) OR (extracts.updated_on > ?)", (args.first || 2.weeks.ago), (args.first || 2.weeks.ago)] }}

  # referencing ExtractsGene
  scope :by_confidence_from_status, lambda {|*args| {:conditions => ["extracts.id IN (SELECT extract_id FROM extracts_genes WHERE extracts_genes.confidence_id = ?)", (args.first || -1)] }}  # pass a Confidence
  scope :by_gene_from_status, lambda {|*args| {:conditions => ["extracts.id IN (SELECT extract_id FROM extracts_genes WHERE extracts_genes.gene_id = ?)", (args.first || -1)] }}  # pass a Gene

  # use with @proj
  scope :without_pcrs, :conditions => "id NOT IN (select extract_id from pcrs)"

  # TODO: move BOTH to shared plugin
  scope :tagged_with_keyword, lambda {|*args| {:include => [:keywords, :tags], :conditions => ["extracts.id IN (SELECT addressable_id FROM tags where addressable_type = 'Extract' AND keyword_id = ?)", (args.first || -1)] }  }
  scope :in_id_range, lambda {|*args| { :conditions => ["extracts.id >= ? and extracts.id <= ?", (args.first || -1), (args[1] || -1)] }  }

  validate :check_record
  def check_record
    errors.add(specimen_id, 'Choose either specimen or lot, not both.') if specimen_id? && lot_id? 
    errors.add(specimen_id, 'Choose a specimen or lot the extract came from.') if specimen_id.blank? && lot_id.blank?
  end
 
  def display_name(options = {})
    @opt = {
      :type => :line # :list, :head, :select, :sub_select, :selected
    }.merge!(options.symbolize_keys)
    s = ''
    case @opt[:type]
    when :selected
      s << " extract_id:#{self.id}"
      if specimen_id && self.specimen.specimen_determinations.size > 0
        s << " (#{self.specimen.most_recent_determination.display_name(:type => :selected)})"
      end
    when :for_select_list
      s = "#{id}: "
      if specimen_id
        s << Specimen.find(specimen_id).display_name(:type => :for_select_list)
      elsif lot_id
        s << Lot.find(lot_id).display_name(:type => :for_select_list)
      end
      s << " " + parts_extracted_from + " #{extracted_on}" if parts_extracted_from
    else
      s << "<div class=\"dn_#{@opt[:type].to_s}\">" 
      s << '<span class="small_grey">extract: </span>' if @opt[:type] == :sub_select
      s << "<div>id: #{id} <span class='small_grey'>from "
      if specimen_id
        s << " specimen id: #{self.specimen_id}"
      elsif lot_id
        s << " lot id: #{self.lot_id}"
      end
      s << "</span></div>"

      if specimen_id && self.specimen.specimen_determinations.size > 0
        s << "<div> #{self.specimen.most_recent_determination.display_name} </div>"
      elsif lot_id
        s << "<div> #{self.lot.display_name} </div>"
      end
      s << '</div>'   
    end 
    s
  end
 
  def display_source_identifiers  # :yields: String identifying the lot or specimen the extract came from
    specimen_id && (return Specimen.find(specimen_id).display_name(:type => :identifiers))
    return Lot.find(lot_id).display_name(:type => :identifiers)
  end
    
  def display_source_determinations  # :yields: String identifying the lot or specimen the extract came from
    specimen_id && (return Specimen.find(specimen_id).display_name(:type => :determinations))
    return Lot.find(lot_id).display_determination
  end
  
  def display_source_ce # :yields: String
    if specimen_id
      return Specimen.find(specimen_id).display_name(:type => :ce_for_list)
    end
    l = Lot.find(lot_id) # it has to have a lot if no specimen
      if l.ce
        return(l.ce.display_for_list)
      else
        return ''
    end
  end

  def otu # :yields: Otu
    if specimen_id
      return (self.specimen.most_recent_determination.otu ? self.specimen.most_recent_determination.otu : self.specimen.most_recent_determination.name)
    elsif lot_id
      return self.lot.otu
    else
      return false 
    end
    false
  end

  def tied_determination # :yields: String
    if specimen_id
      return self.specimen.display_name(:type => :verbose_taxon) 
    elsif lot_id
      return self.lot.otu.display_name
    end
    false
  end

  def count_seqs_with_nucs_by_gene(gene) # :yields: Integer
   pcrs = gene.primer_pairs.inject([]){|sum, pair| sum += self.pcrs.by_primer_pair(pair[0], pair[1])}.flatten 
   pcrs.inject(0){|sum, p| sum + p.seqs.with_nucleotides.size } 
  end

  def self.summarize_by(options = {})
    result = {:genes => [], :extracts => []}
 
    result[:extracts] += Specimen.find(options[:specimen_id]).extracts                                                  if !options[:specimen_id].blank?
    result[:extracts] += OtuGroup.find(options[:otu_group_id]).extracts                                                 if !options[:otu_group_id].blank?
    result[:extracts] += Otu.find(options[:otu_id]).extracts                                                            if !options[:otu_id].blank?
    result[:extracts] += Extract.tagged_with_keyword(Keyword.find(options[:keyword_id]))                                if !options[:keyword_id].blank? 

    result[:extracts] += Extract.by_proj(options[:proj_id]).by_confidence_from_status(options[:extract_confidence_id])  if !options[:extract_confidence_id].blank? 

    ArrayHelper.range_as_array(options[:extract_range]).each do |i|
      if e = Extract.find_by_id_and_proj_id(i, options[:proj_id])
        result[:extracts] += [e]
      end
    end
    
    result[:genes] += GeneGroup.find(options[:gene_group_id]).genes if !options[:gene_group_id].blank?
    result[:genes] += [Gene.find(options[:gene_id])] if !options[:gene_id].blank?
    result[:genes] += [Primer.find(options[:primer_id]).gene] if !options[:primer_id].blank?

    result[:extracts].uniq!
    result[:genes].uniq!

    result[:extracts].sort!{|a,b| a.id <=> b.id} 
    result[:genes].sort!{|a,b| a.name <=> b.name}

    result
  end

  def self.find_for_auto_complete(value) # :yields: Array of Extracts
   find_by_sql [
      "SELECT e.* FROM extracts e
      LEFT JOIN specimens s on e.specimen_id = s.id
      LEFT JOIN identifiers i ON s.id = i.addressable_id
      LEFT JOIN specimen_determinations sd ON s.id = sd.specimen_id
      LEFT JOIN otus o on o.id = sd.otu_id
      LEFT JOIN taxon_names t ON o.taxon_name_id = t.id 
      LEFT JOIN ces c on s.ce_id = c.id
      LEFT JOIN geogs g on c.geog_id = g.id
      WHERE e.proj_id = #{$proj_id}
      AND (
       e.id = ? OR
       e.specimen_id = ? OR 
       o.name LIKE ? OR
       o.matrix_name LIKE ? OR
       o.manuscript_name LIKE ? OR
       t.name LIKE ? OR
       (i.identifier LIKE ? AND i.addressable_type = 'Specimen') OR
       sd.name LIKE ? OR
       g.name LIKE ? OR
       c.verbatim_label LIKE ?
      ) LIMIT 30",
       value,
       value,
       "#{value.downcase}%",
       "%#{value.downcase}%",
       "%#{value.downcase}%",
       "#{value.downcase}%",
       "%#{value.downcase}%",
       "%#{value.downcase}%",
       "%#{value.downcase}%",
       "%#{value.downcase}%"
      ]
  end


end
