# == Schema Information
# Schema version: 20090930163041
#
# Table name: genes
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  notes      :text
#  position   :integer(4)
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

class Gene < ActiveRecord::Base 
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::DefaultNamedScopes

  has_many :primers, :dependent => :nullify
  has_many :seqs, :dependent => :nullify 

  has_many :pcrs, :class_name => 'Pcr', :finder_sql => 'SELECT DISTINCT p.* from pcrs p
    WHERE p.id IN (SELECT id from ((SELECT g1.id from genes g1 join primers pf on pf.gene_id = #{id}) UNION (SELECT g2.id from genes g2 join primers pr on pr.gene_id = #{id})) t1);'

  has_and_belongs_to_many :gene_groups
  
  acts_as_list :scope => :proj
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => 'proj_id'

  # Careful- likely excludes possible results
  scope :used_in_seqs_from_otu, lambda {|*args| {:conditions => ["id IN (SELECT gene_id FROM seqs WHERE otu_id = ?)", (args.first || -1)] }}

  def display_name(options = {}) # :yields: String Gene#name
    name
  end

  def primer_pairs # :yields: an array of arrays of all possible primer pairs [[fwd1, rev1], [fwd2, rev2] ... ] given primers attached to this gene
    # note that some are nonsense, but these will just return nil results when this method is usd
    pairs = []
    self.primers.each do |p1|
      self.primers.each do |p2|
        pairs << [p1,p2] if !(p1 == p2)
      end
    end
    pairs
  end

  # returns all possible pcrs that match a primer pair in self#primer_pairs 
  #  def pcrs
  #    self.primer_pairs.inject([]){|sum, pp| sum += Pcr.by_primer_pair(pp[0], pp[1])}.flatten
  #  end

end
