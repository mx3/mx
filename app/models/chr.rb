# == Schema Information
# Schema version: 20090930163041
#
# Table name: chrs
#
#  id               :integer(4)      not null, primary key
#  name             :string(255)     not null
#  cited_in         :integer(4)
#  cited_page       :string(64)
#  cited_char_no    :string(4)
#  revision_history :text
#  syn_with         :integer(4)
#  doc_char_code    :string(4)
#  doc_char_descr   :text
#  short_name       :string(6)
#  notes            :text
#  continuous       :boolean(1) # DEPRECATED for is_continuous
#  ordered          :boolean(1)
#  position         :integer(4)
#  proj_id          :integer(4)      not null
#  creator_id       :integer(4)      not null
#  updator_id       :integer(4)      not null
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null
#  standard_view_id

class Chr < ActiveRecord::Base

  # Characters are defined to represent/accept 3 general data types: 1) Typical multistate characters; 2) Continuous characters that accept any value; 3) Continuous characters that are derived from measurements placed on specimens.  TODO: complete 2 & 3

  has_standard_fields 
  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  acts_as_list :scope => :proj_id
    
  belongs_to :cited_in_ref, :class_name =>"Ref", :foreign_key => "cited_in" ## should get changed to cited_in_id or just ref_id
  belongs_to :chr_syn_with, :class_name =>"Chr", :foreign_key => "syn_with"
  belongs_to :continuous_description, :class_name => 'StandardView', :foreign_key => 'standard_view_id' # the continuous character mapping

  has_many :chr_states, :dependent => :destroy, :order => 'state'
  has_many :codings, :dependent => :destroy
  has_many :otus, :through => :codings
  has_many :chr_groups_chrs
  has_many :chr_groups, :through => :chr_groups_chrs, :source => :chr_group

  has_many :mxes_minus_chrs, :dependent => :destroy
  has_many :mxes_plus_chrs, :dependent => :destroy
  has_many :chrs_mxes, :dependent => :destroy
  has_many :mxes, :through => :chrs_mxes, :order => 'mxes.name'

  # need to validate their destruction!
  validates_length_of :short_name, :in => 0..6, :allow_nil => true
  validates_presence_of :name
  validate :check_continuous_settings

  before_destroy :remove_from_matrices
  after_update :check_continuous_state_state

  # TODO: before_save filter to update non normalized Codings

  # Can use like foo_mx.chrs_coded_in_matrix OR Chr.coded_in_matrix(mx.id)
  scope :coded_in_matrix, lambda {|*args| {:conditions => "chrs.id IN (SELECT chr_id FROM chrs_mxes WHERE mx_id " + (args.first ? ["= ?", args.first] : 'like "%"') + ") AND chrs.id IN (SELECT chr_id FROM codings)" } }
  scope :not_coded_in_matrix, lambda {|*args| {:conditions => "chrs.id IN (SELECT chr_id FROM chrs_mxes WHERE mx_id " + (args.first ? ["= ?", args.first] : 'like "%"') + ") AND chrs.id NOT IN (SELECT chr_id FROM codings)"}} 
  scope :without_groups, :conditions => 'id NOT IN (SELECT chr_id FROM chr_groups_chrs)'
  scope :coded_for_otu, lambda {|*args| {:conditions => ["chrs.id IN (SELECT chr_id FROM codings WHERE otu_id = (?))", args.first.id]}}
  scope :recently_changed_by_chr_state, lambda {|*args| {:include => :chr_states, :conditions => ["(chr_states.created_on > ?) OR (chr_states.updated_on > ?)", (args.first || 2.weeks.ago), (args.first || 2.weeks.ago)] }}
  scope :within_mx_range, lambda {|*args| {:include => :chrs_mxes, :conditions => ["chrs_mxes.position >= ? AND chrs_mxes.position <= ?", (args.first || -1), (args[1] || -1)]}} 
  scope :not_in_matrices, :conditions => 'chrs.id NOT IN (SELECT chr_id from chrs_mxes)', :order => 'chrs.name'

  scope :that_are_multistate, :conditions => 'chrs.is_continuous != true AND chrs.standard_view_id is null' 
  scope :that_are_continuous, :conditions => '(chrs.is_continuous = 1 OR chrs.standard_view_id IS NOT null)' 

  # return all unique characters coded by the passed [] of states
  def self.by_states(states)
     return nil if states.size == 0
     sql = states.inject([]){|sum, o| sum << "chr_states.id = #{o}"}.join(' OR ')
     Chr.find(:all, :include => 'chr_states', :conditions => sql)
  end

  # this is really a matrix formatting (e.g. Phylip)
  def display_states
    self.chr_states.map{|state| state.name.gsub(/[\W]/ , "_")}.join(" ")
  end

  def display_name(options = {})
    opt = {
      :type => :select, # 
    }.merge!(options.symbolize_keys)
    case opt[:type]
    when :select
      name
    else
      name
    end
  end

  # TODO: deprecate for display_name(:type) 
  def display_matrix_name # no spaces
     name.gsub(/[\W]/ , "_")
  end

  # TODO: deprecate(?)
  def display_number_states_coded # return the number of times this character has been coded for
    self.codings.count
  end
  
  def child_synonyms
    Chr.find_all_by_syn_with(id)
  end

  def dupe
    c = Chr.new
    c = self.clone
    c.name = "[CLONED] " + c.name
    c.save
    for cs in self.chr_states
      csn = cs.clone
      c.chr_states << csn
    end
    c
  end

  # a display method states (txt)
  def states
    self.chr_states.collect{|cs| cs.state}.sort
  end

  def continuous?
    true if !standard_view_id.blank? || is_continuous
  end

  # TODO:stub
  def self.read_microformat(options = {})
    @opts = {
    }.update(options.symbolize_keys)

    return false if ! @opts[:file]

    return -1 # not written yet
    # turms = @f.split(/\n{1,}/).map {|x| x.strip} # read the contents of the uploaded file
    # terms = turms.inject({}) {|sum, t| sum.update(t => nil)} 
  end

  protected
    
  def remove_from_matrices
    # subtract from +/-
    self.mxes.each do |m|
      m.remove_from_plus(self)
      m.remove_from_minus(self)
    end

   # can also belong to a chr_group and therefor a mx
   # subtract from any groups
    self.chr_groups.each do |cg|
      cg.remove_chr(self)
    end
  end

  def check_continuous_state_state
    # if this character is continuous it has no states!
    if self.continuous?
      self.chr_states.destroy_all # this chains to destroy the codings
    end
    true
  end

  def check_continuous_settings
    if is_continuous && !standard_view_id.blank?
      errors.add(:is_continuous, "Choose only one option for continuous characters.")
    end
  end


end
