# == Schema Information
# Schema version: 20090930163041
#
# Table name: specimens
#
#  id                 :integer(4)      not null, primary key
#  ce_id              :integer(4)
#  temp_ce            :text
#  parent_specimen_id :integer(4)
#  repository_id      :integer(4)
#  dna_usable         :boolean(1)
#  notes              :text
#  sex                :string(64)
#  stage              :string(64)
#  proj_id            :integer(4)      not null
#  creator_id         :integer(4)      not null
#  updator_id         :integer(4)      not null
#  updated_on         :timestamp       not null
#  created_on         :timestamp       not null
#  preparations       :text  DEPRECATED
#  disposition        :string(255)
#

class Specimen < ActiveRecord::Base
  set_table_name('specimens')
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::Identifiable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods
  
  # See /config/initializers/constants.rb for SEX constant

  has_one :most_recent_determination, :class_name => 'SpecimenDetermination', :order => 'det_on DESC, created_on DESC'
  has_one :ipt_record, :dependent => :destroy

  belongs_to :ce 
  belongs_to :image_description 
  belongs_to :parent_specimen, :class_name => "Specimen", :foreign_key => "parent_specimen_id" # may need to adjust
  belongs_to :repository
  belongs_to :preparation, :foreign_key => :preparation_protocol_id, :class_name => 'Protocol'

  has_many :extracts, :dependent => :destroy
  has_many :measurements, :dependent => :destroy
  has_many :otus, :through => :specimen_determinations, :source => :otu
  has_many :specimens, :class_name => "Specimen", :foreign_key => "parent_specimen_id"
  has_many :images, :through => :image_descriptions 
  has_many :image_descriptions
  has_many :specimen_determinations, :dependent => :delete_all, :before_add => :validate_determination
  has_many :taxon_names, :through => :specimen_determinations, :source => :taxon_name
  has_many :seqs, :dependent => :nullify 
  has_many :type_assignments, :through => :type_specimens, :source => :taxon_name

  has_many :type_specimens, :dependent => :delete_all
  
  scope :with_usable_dna, :conditions => {:dna_usable => true} 
  scope :determined_as_otu, lambda {|*args| {:conditions => ["specimens.id IN (SELECT specimen_id from specimen_determinations WHERE specimen_determinations.otu_id = ?)", (args.first || -1)] }}
  scope :with_type_status, lambda {|*args| {:conditions => ["specimens.id IN (SELECT specimen_id from type_specimens WHERE type_type = ?)", (args.first || -1)] }}
  scope :with_type_assignment_for_taxon_name, lambda {|*args| {:conditions => ["specimens.id IN (SELECT specimen_id from type_specimens WHERE taxon_name_id = ?)", (args.first || -1)] }}
  scope :include_has_manys, :include => [:repository, :ce, {:specimen_determinations => {:otu => :taxon_name}}, :creator]

  # Thanks to folks at Stack Exchange for help with this
  scope :with_current_determination, lambda {|*args| 
    { :joins => "JOIN (specimen_determinations sda, otus) " +
        "ON (sda.specimen_id = specimens.id AND sda.otu_id = otus.id) " +
        "LEFT JOIN specimen_determinations sdb " +
        "ON (sdb.specimen_id = specimens.id AND sda.det_on < sdb.det_on)", 
      :conditions => ["sdb.id IS NULL AND otus.id = ?", (args.first || -1)]
    }
  }

  # thanks to folks at Stack Exchange for help with this
  scope :with_current_determination_and_member_of_taxon, lambda {|*args| 
    { :joins => "JOIN (specimen_determinations sda, otus) " +
        "ON (sda.specimen_id = specimens.id AND sda.otu_id = otus.id) " +
        " JOIN (taxon_names t) " +
        " ON (otus.taxon_name_id = t.id) " + 
        "LEFT JOIN specimen_determinations sdb " +
        "ON (sdb.specimen_id = specimens.id AND sda.det_on < sdb.det_on)", 
      :conditions => ["sdb.id IS NULL AND t.l >= ? AND t.r <= ? ", (args.first.l || -1), (args.first.r || -1)]
    }
  }

  scope :with_identifiers, :joins => :identifiers
  scope :without_type_assignment, {:conditions =>  "specimens.id NOT IN (select specimen_id FROM type_specimens)"}
  scope :that_are_mappable, :include => [:ce], :conditions => "length(ces.latitude) > 0 AND length(ces.longitude) > 0"

  def validate_determination(determination)
    if !determination.otu && determination.name.blank?
      errors.add(:base, "Specimen determination needs a name or OTU.")
      raise ActiveRecord::RecordInvalid, self
    end
  end

  # TODO: validate that parent isn't part of ancestors

  after_update :save_measurements

  def measurement_attributes=(measurement_attributes)
    measurement_attributes.each do |attributes|
      next if attributes == {} 
      if attributes[:id].blank? 
        measurements.build(attributes)
      else
        a = measurements.detect { |t| t.id == attributes[:id].to_i }
        a.attributes = attributes
      end
    end
    true
  end
 
  def save_measurements
    measurements.each do |a|
      if a.measurement.blank?  # measurements of 0 are allowed!!
        a.destroy 
      else
        a.save(true) # passing false ignores validation -- ugh!
      end
    end
  end

  def measurement_for(options = {})
    opt = {
      :units => nil,
      :standard_view_id => nil,
      :conversion_factor => nil
    }.merge!(options)

    return nil if opt[:standard_view_id].nil?
    opt.collect{|o| opt.delete(o) if opt[o].nil?}

    Measurement.find(:first, :conditions => opt.merge(:specimen_id => self.id))
  end
 
  def display_name(options = {})
    opt = {
      :type => :identifiers, 
      :otu => nil,
      :taxon_name => nil,
      :target => ""
    }.merge!(options.symbolize_keys)

    xml = Builder::XmlMarkup.new(:indent=> 2, :target => opt[:target])

    case opt[:type]
    when :identifiers
      if identifiers.size > 0
        xml << identifiers.map{|i| "#{i.cached_display_name}"}.join("; ")  
      else
        xml << "mx_id: #{self.id}"
      end
    when :in_list
      (self.display_name(:type => :identifiers) == 'id: #{id.to_s}' ? '' : " id:#{id.to_s} #{self.display_name(:type => :identifiers)} / ") + "(#{(self.most_recent_determination ? self.most_recent_determination.display_name : "no dets")})"
    when :for_select_list
      if self.display_name(:type => :identifiers) == 'mx_id: #{id.to_s}'
        xml << ''
      else
        xml << "#{self.display_name(:type => :identifiers)} : "
      end
      if self.most_recent_determination
        xml << self.most_recent_determination.display_name(:type => :for_select_list) 
      else
        xml.i("no determinations")
      end 
      xml <<  " <span style='color:grey;font-size:smaller;'>mx_id:#{id.to_s}</span>"
    when :selected
      xml << self.display_name(:type => :select)
    when :taxon # returns a string 
      if self.most_recent_determination
        xml << self.most_recent_determination.display_name(:type => :selected)
      else
        xml << "no determinations"
      end 
    when :verbose_taxon # returns a string 
      if self.most_recent_determination
        xml << self.most_recent_determination.display_name(:type => :with_OTU_id_when_present)
      else
        xml << "no determinations"
      end 
    when :determinations
      @dets = SpecimenDetermination.find_all_by_specimen_id_and_current_det(id, true)
      xml << 'no determinations'  if @dets.empty?
      xml <<  @dets.map{|i| i.display_name }.join("; ")
    when :ce_for_list
      ce = self.ce.andand.display_name(:type => :verbose)
      xml << ce if !ce.nil?
      xml << self.temp_ce[0..40] if self.temp_ce
    else
      xml.div("class" => "dn_#{opt[:type].to_s}") do |i|
        xml.div("id: #{id}", "class" => "dnsid")
        xml.span("specimen: ", "class" => "hd") if opt[:type] == :sub_select 
        xml.div(self.most_recent_determination.display_name, "class" => "small_grey", "style" => "float:right") if self.specimen_determinations.count > 0 
        xml.div(self.display_name(:type => :identifiers), "class" => "small_grey") if self.identifiers.size > 0
        xml << self.ce.display_name(:type => :sub_select) if self.ce 
      end 
    end
    opt[:target] 
  end

  def verbose_material_examined_string(options = {}) # :yields: String, as used in /lib/material_examined.rb
    s = ''
    if options[:otu]
      s << "#{self.type_status_by_otu(options[:otu])}".downcase.capitalize
    elsif options[:taxon_name]
      s << "#{self.type_assignments.with_taxon_name_assignment(options[:taxon_name]).collect{|ts| ts.type_type.downcase.capitalize}}"  # review
    end
    s << " #{self.sex.blank? ? "SEX NOT PROVIDED" : self.sex}: #{self.ce.blank? ? "NO COUNTRY PROVIDED THROUGH GEOG" : self.ce.geog.country.name.upcase}: "
    s << [(self.ce.blank? ? "NO COLLECTING EVENT PROVIDED" :  self.ce.display_name(:type => :verbose_material_examined_string)), "#{self.identifiers.collect{|si| si.cached_display_name}.join(",")} (deposited in #{self.repository.coden})"].compact.join(", ")
    s <<  "."
  end

  def sequences # :yields: Array of Sequences
    s = []
    s += self.seqs
    self.extracts.collect{|e| s += e.seqs}
    s.compact.uniq 
  end

  def most_recent_otu_determination # :yields: A OTU or nil, ignores determinations not bound to OTUs
    return self.most_recent_determination.otu if self.most_recent_determination && self.most_recent_determination.otu
    nil
  end

  def mappable # :yields: True or False
    return true if self.ce && self.ce.mappable
    false
  end
    
  # TODO: Deprecate, redundant with above
  def has_lat_long # :yields: True or False
    if self.ce and !self.ce.latitude.blank? and !self.ce.longitude.blank?
      return true
    end
    false
  end

  def self.find_by_identifiers(options = {}) # :yields: Array of Specimens
    opt = {
      :string => '',     # String
      :project => nil    # Project
    }.merge!(options)
  
    return [] if opt[:string].andand.length == 0 || opt[:project].class != Proj
  
    s = opt[:string].split.collect{|str| str.strip}.compact.uniq
    sql = s.inject([]) {|sum, s| sum << "(identifiers.identifier LIKE \"%#{s}%\")"}.join(" OR ")
   
    find(:all, :conditions => "(" + sql + ") and specimens.proj_id = #{opt[:project].id}", :include => [:identifiers])
  end 

  def self.group_update(params) # :yields: Array of Specimens | false
    temp_specimen_determination = SpecimenDetermination.new(params['specimen_determination'])
    $proj_id ||=  params[:project]
    result = []
    begin
      Specimen.transaction do 
        params['specimens'].each do |s|
          if specimen = Specimen.find(s, :include => [:identifiers, :specimen_determinations])

            if params['delete_exsisting_determinations'] == "1"
              specimen.specimen_determinations.destroy_all
            end

            sd = temp_specimen_determination.clone
            specimen.specimen_determinations << sd
            specimen.save! 
            result.push(specimen)
          end
        end
      end
    rescue
      return false 
    end
    return result  
  end

  # Returns this specimens type status string, or false, for the given Otu
  # Rules- if Otu#taxon_name.blank? then all statuses NOT tied to a taxon name are returned
  #         (Pragmatically there should only be one pre-press assignment, otherwise you have some messed up decision making)
  #        if Otu#taxon_name then grab the status for that TaxonName
  def type_status_by_otu(otu) # :yields: String || false
    if otu.taxon_name.blank?
      return self.type_specimens.without_taxon_name_assignment.collect{|t| t.type_type}.join(",") if self.type_assignments.count > 0
    else
      return self.type_specimens.with_taxon_name_assignment(otu.taxon_name.id).collect{|t| t.type_type}.join(",") if self.type_assignments.count > 0
    end
    return false
  end

  def make_clone # :yields: Specimen
    s = self.clone
    s.created_on = Time.now
    s.updated_on = Time.now
    
    s.save
    s.identifiers.destroy_all

    if sd = self.most_recent_determination.andand.clone
      sd.specimen_id = s
      s.specimen_determinations << sd
    end
    s.save
    s
  end

  def self.find_for_auto_complete(value)
    find_by_sql [
      "SELECT DISTINCT s.* FROM specimens s 
      LEFT JOIN identifiers i ON i.addressable_id = s.id
      LEFT JOIN specimen_determinations sd ON s.id = sd.specimen_id
      LEFT JOIN otus o on o.id = sd.otu_id
      LEFT JOIN taxon_names t ON o.taxon_name_id = t.id 
      LEFT JOIN ces c on s.ce_id = c.id
      LEFT JOIN geogs g on c.geog_id = g.id
      WHERE s.proj_id = #{$proj_id} 
      AND (s.id = ? OR
           o.name LIKE ? OR
           c.verbatim_label LIKE ? OR 
           matrix_name LIKE ? OR
           o.manuscript_name LIKE ? OR
           t.name LIKE ? OR
           (i.cached_display_name LIKE ? AND i.addressable_type = 'Specimen') OR 
           i.identifier = ? OR
           sd.name LIKE ? OR 
           g.name LIKE ? OR
           c.verbatim_label LIKE ?)
      LIMIT 30",
      "#{value}", "#{value.downcase}%", "%#{value.downcase}%", "%#{value.downcase}%", "%#{value.downcase}%", "#{value.downcase}%", "%#{value}%", value, "%#{value.downcase}%", "%#{value.downcase}%", "%#{value.downcase}%"]
  end

end



