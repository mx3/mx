# == Schema Information
# Schema version: 20090930163041
#
# Table name: pcrs
#
#  id            :integer(4)      not null, primary key
#  extract_id    :integer(4)
#  fwd_primer_id :integer(4)
#  rev_primer_id :integer(4)
#  protocol_id   :integer(4)
#  gel_image_id  :integer(4)
#  lane          :integer(1)
#  done_by       :string(255)
#  result        :string(24)
#  notes         :text
#  proj_id       :integer(4)      not null
#  creator_id    :integer(4)      not null
#  updator_id    :integer(4)      not null
#  updated_on    :timestamp       not null
#  created_on    :timestamp       not null
#

class Pcr < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  belongs_to :fwd_primer, :class_name => "Primer", :foreign_key => "fwd_primer_id"
  belongs_to :rev_primer, :class_name => "Primer", :foreign_key => "rev_primer_id"
  belongs_to :confidence
  belongs_to :extract
  belongs_to :protocol
  
  belongs_to :gel_image # TODO: not implemented yet

  has_many :chromatograms, :dependent => :destroy
  has_many :seqs 

  # the possible "genes" tied to this (primers are assigned to a single gene at present, these may be the same -> need to revisit this model at some point)
  has_many :genes, :class_name => 'Gene', :finder_sql => proc {"select distinct g.* FROM genes g
     WHERE g.id IN (SELECT DISTINCT gene_id FROM
    ((SELECT gene_id FROM primers WHERE primers.id = #{rev_primer_id}) UNION
     (SELECT gene_id FROM primers WHERE primers.id = #{fwd_primer_id})) t1) ORDER BY g.id;"}
  
  validates_presence_of :rev_primer
  validates_presence_of :fwd_primer

  # may have to elimiante this
  validates_presence_of :extract 

  scope :by_primer_pair, lambda {|*args| {:conditions => ['fwd_primer_id = ? AND rev_primer_id = ?', (args.first || -1), (args[1] || -1)], :include => [:rev_primer, :fwd_primer, :extract, :seqs]} }
  scope :by_extract, lambda {|*args| {:conditions => ['extract_id = ?', (args.first || -1)]} }
  scope :with_sequence_nucleotides, :include => [:seqs], :conditions => 'length(seqs.sequence) > 0'

  def display_name(options = {})
     @opt = {
      :type => :line # :selected, :list, :list_short
     }.merge!(options.symbolize_keys)
     str = ''
     case @opt[:type]
     when :selected
       str << "id: #{id} - [#{fwd_primer.name} / #{rev_primer.name}]"
       str <<  self.extract.display_name(:type => :selected) 
     when :list
       str <<  self.confidence.open_background_color_span if self.confidence
       str << "id: #{id} - [#{fwd_primer.name} / #{rev_primer.name}]"
       str << '</span>' if self.confidence
     when :confidence
       str <<  self.confidence.open_background_color_span if self.confidence
       str << "#{id}"
       str << '</span>' if self.confidence
     else 
       str << '<div class="dn_' + @opt[:line].to_s + '"'
       str << " style=\"border:2px solid ##{self.confidence.html_color};\"" if self.confidence  
       str << '>' 
       str << "<div>id: #{id} <span class='small_grey'>#{fwd_primer.gene.name} [#{fwd_primer.name} / #{rev_primer.name}] </div>"
       str <<  self.extract.display_name(:type => :sub_select) 
       str << "</div>"
     end
     str
  end

  def otu # :yields: Otu | nil 
   self.extract.otu.class.name == "Otu" ? self.extract.otu : nil
  end

  def gene_name # :yields: String corresponding to the gene name, because gene labels are attached at primer level it's possible for primer pairs to be used with several genes
    [self.fwd_primer.gene.name, self.rev_primer.gene.name].uniq.join("/")
  end

  def gene_name_array # :yields: Array of Gene.name
    [self.fwd_primer.gene, self.rev_primer.gene].uniq
  end

  def self.batch_create(options = {})
    @pcrs = []
    return false if !options[:extract]
    Pcr.transaction do
      begin
        options[:extract].sort.each do |e|
          p = Pcr.new(:extract_id => e[1], :fwd_primer_id => options[:pcr][:fwd_primer_id], :rev_primer_id => options[:pcr][:rev_primer_id], :proj_id => options[:proj_id], :notes => options[:pcr_notes], :protocol_id => ((options[:pcr] && options[:pcr][:protocol_id]) ? options[:pcr][:protocol_id] : nil), :done_by => options[:done_by])
          p.save!
          @pcrs << p
        end
      rescue  #ActiveRecord::RecordInvalid
        raise
      end
    end
    return @pcrs
  end

  def self.find_for_auto_complete(value)
   find_by_sql [
      "SELECT DISTINCT p.* FROM pcrs p
      LEFT JOIN extracts e on e.id = p.extract_id 
      LEFT JOIN primers pf on p.fwd_primer_id = pf.id
      LEFT JOIN primers pr on p.rev_primer_id = pr.id
      LEFT JOIN specimens s on e.specimen_id = s.id
      LEFT JOIN identifiers i ON s.id = i.addressable_id
      LEFT JOIN specimen_determinations sd ON s.id = sd.specimen_id
      LEFT JOIN otus o on o.id = sd.otu_id
      LEFT JOIN taxon_names t ON o.taxon_name_id = t.id 
      LEFT JOIN ces c on s.ce_id = c.id
      LEFT JOIN geogs g on c.geog_id = g.id
      WHERE p.proj_id = #{$proj_id}
      AND (p.id LIKE ? OR
           p.notes LIKE ? OR
           e.id = ? OR
           pf.name LIKE ? OR
           pr.name LIKE ? OR
           e.specimen_id = ? OR
           o.name LIKE ? OR
           o.matrix_name LIKE ? OR
           o.manuscript_name LIKE ? OR
           t.name LIKE ? OR
           (i.cached_display_name LIKE ? AND i.addressable_type = 'Specimen') OR
           sd.name LIKE ? OR
           g.name LIKE ? OR
           c.verbatim_label LIKE ?) LIMIT 40",
       "#{value}", "%#{value.downcase}%", "#{value}", "%#{value.downcase}%",  "%#{value.downcase}%", "#{value}", "#{value.downcase}%", "%#{value.downcase}%", "%#{value.downcase}%", "#{value.downcase}%", "%#{value.downcase}%", "%#{value.downcase}%", "%#{value.downcase}%", "%#{value.downcase}%"]
  end

  def self.default_vol
      {:dntp => 0.5,
       :buffer => 2.5,
       :mg =>  2.0,
       :taq => 0.25,
       :primers => 1.0,
       :templ => 1.5,
       :water => 16.25,
       :rxn_vol => 25,
       :other => 0.0
      } 
  end

end
