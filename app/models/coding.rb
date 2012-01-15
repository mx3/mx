
class Coding < ActiveRecord::Base 
  has_standard_fields

  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  belongs_to :otu
  belongs_to :confidence
  belongs_to :chr
  belongs_to :chr_state
  belongs_to :ref

  scope :in_matrix, lambda {|*args| {:include => :confidence, :conditions => ["(codings.chr_id IN (SELECT chr_id FROM chrs_mxes WHERE chrs_mxes.mx_id = ?)) AND (codings.otu_id IN (SELECT otu_id FROM mxes_otus WHERE mxes_otus.mx_id = ?))", (args.first || -1), (args.first || -1)]}}
  scope :in_chr_group, lambda {|*args| {:conditions => ["codings.chr_id IN (SELECT chr_id FROM chr_groups_chrs WHERE chr_group.id = ?)", args.first || -1]}} 

  # while these are easy to get from Chr, or OTU, they are nice for chaining, like Otu.codings.by_chr(Chr).with_confidence(Confidence), if nothing is passed [] returned
  scope :by_chr, lambda {|*args| {:conditions => ["codings.chr_id = ?", args.first || -1]}}  
  scope :by_otu, lambda {|*args| {:conditions => ["codings.otu_id = ?", args.first || -1]}}  
  
  scope :unique_for_otu, lambda {|*args| {:conditions => ["(codings.otu_id = ?) 
    AND codings.id IN (SELECT id FROM (select id, count(chr_state_id) AS cnt FROM codings GROUP BY chr_state_id HAVING cnt = 1) as c )", args.first || -1]}}  

  #  scope :coded_once, {:conditions => 

  scope :ordered_by_chr, :include => :chr, :order => 'chrs.name ASC'

  validates_presence_of [:otu_id, :chr_id]
  validates_uniqueness_of :otu_id, :scope => [:chr_id, :chr_state_id]

  validate :chr_and_chr_state_ids_belong_together? # the should, but bugs are appearing
  validate :either_continuous_value_or_chr_state_id_present
  validate :only_one_of_continuous_value_or_chr_state_id_present

  before_save :set_non_normalized # speed ups for display

  # make this a named scope
  def similarly_coded_otus
    Coding.find(:all, :conditions => "(chr_id = #{self.chr_id} AND chr_state_id = #{self.chr_state_id})")
  end

  def display_name(options = {})
    opt = {}.merge!(options)
    case opt[:type]
    when :value
      return continuous_state.to_s if !continuous_state.blank? 
      return chr_state_state if !chr_state_state.blank?
      ""
    when :windowed_value
      return '#' if !continuous_state.blank?
      return chr_state_state if !chr_state_state.blank?
    else
      "id: " + id.to_s
    end
  end

  def display_wrapped_in_confidence
    return self.display_name(:type => :windowed_value) if self.confidence_id.blank?
    "#{self.confidence.open_background_color_span}#{self.display_name(:type => :windowed_value)}</span>" 
  end

  def display_wrapped_in_age_heat_map
    i = 255 - (255 - (Time.now - self.created_on).round / 86400).round
    i = 255 if i > 255 || i < 0
    # basically the same values below
    # j = 255- (Time.now - self.updated_on).round / 86400 
    # j = 255 if j > 255 || j < 0
    "<span style=\"background-color:rgb(0,#{i},0);padding: 2px;\">#{self.display_name(:type => :windowed_value)}</span>"
  end
  
  def display_wrapped_in_tag_heat_map
   if self.tags.count == 1 
      "<div style=\"background-color:##{self.tags.first.keyword.html_color}; width: 10; border: 1px solid #8b2973; font-weight: bolder; margin: 0;\">#{self.display_name(:type => :windowed_value)}</div>"
    elsif self.tags.count > 1
      i = 255 - (self.tags.count * 20) 
      i = 255 if i < 0
      "<div style=\"background-color:rgb(0,#{i},#{i}); width: 10; border: 1px solid #e5993a; color: white; margin: 0;\">#{self.display_name(:type => :windowed_value)}</div>"
    else 
      self.display_name(:type => :windowed_value) 
    end
  end

  def display_wrapped_in_creator_heat_map
    if !self.creator.pref_creator_html_color.blank?
      i = self.creator.pref_creator_html_color
    else
      i = (255 - (2 * self.creator_id)).round
      i = 0 if i < 0
      i = "%x" % i
      i = "eeee#{i}" 
    end
    "<span style=\"background-color:##{i}; padding: 2px;\">#{self.display_name(:type => :windowed_value)}</span>"
  end

  # requires Otu and Chr
  def self.destroy_by_otu_and_chr(otu, chr)
    @otu = otu
    @chr = chr
    return false if !@otu and !@chr
    Coding.find(:all, :conditions => ["otu_id = ? AND chr_id = ?", @otu.id, @chr.id]).each {|c| c.destroy}
    true
  end

  # TODO: formalize debugging, put this elsewhere
  def self.invalid(proj_id)
    invalid_codings = []
    self.by_proj(proj_id).each do |c|
      invalid_codings.push(c) if !Chr.find(c.chr_id).chr_states.collect{|cs| cs.id}.include?(c.chr_state_id)
    end
    invalid_codings
  end

  private 

  def chr_and_chr_state_ids_belong_together?
    return false if self.chr_id.blank?
    if !chr_state_id.blank? && !Chr.find(chr_id).chr_states.collect{|cs| cs.id}.include?(chr_state_id)
      errors.add(:chr_state_id, "Character and character state bug, contact your administrator.")
    end
    true
  end

  def only_one_of_continuous_value_or_chr_state_id_present
    if !continuous_state.blank? && !chr_state_id.blank? 
      errors.add(:chr_state_id, "You can't have both a continuous state value and a character state id.")
    end
  end

  def either_continuous_value_or_chr_state_id_present
    if continuous_state.blank? && chr_state_id.blank?
      errors.add(:chr_state_id, "You must have one of chr_state_id or continuous value.")
    end
  end


  def set_non_normalized
    if !self.chr_state_id.blank?
      self.chr_state_state = self.chr_state.state if self.chr_state_state.blank? # HUH? shouldn't this be !self.foo.blank?
      self.chr_state_name = self.chr_state.name if self.chr_state_name.blank?
    end
  end

end
