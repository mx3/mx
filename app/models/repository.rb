# == Schema Information
# Schema version: 20090930163041
#
# Table name: repositories
#
#  id                 :integer(4)      not null, primary key
#  name               :text            default(""), not null
#  coden              :string(12)
#  url                :text
#  synonymous_with_id :integer(4)
#  creator_id         :integer(4)      not null
#  updator_id         :integer(4)      not null
#  updated_on         :timestamp       not null
#  created_on         :timestamp       not null
#

class Repository < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::Identifiable

  has_many :lots
  has_many :specimens
  has_many :type_specimens, :through => :specimens

  # this may be merged with type_specimens, above
  has_many :type_taxon_names, :class_name => "TaxonName", :foreign_key => "type_repository_id", :order => "l"
  
  has_many :type_specimen_taxon_names, :class_name => "TaxonName", :finder_sql =>
      'SELECT DISTINCT taxon_names.* FROM specimens ' +
      'LEFT JOIN type_specimens ON specimens.id = type_specimens.specimen_id ' +
      'LEFT JOIN taxon_names ON type_specimens.taxon_name_id = taxon_names.id ' +
      'WHERE specimens.repository_id = #{id} AND taxon_names.id IS NOT NULL ' +
      'ORDER BY taxon_names.l'

  validates_presence_of :name

  def display_name(options = {})
    opt = {
     :type => nil
    }.merge!(options.symbolize_keys)

    s = ''

    case opt[:type]
    when :selected
      name
    when :for_select_list
      (coden? and name?) ? "#{coden} - #{name}" : "#{coden}#{name}"
    else
      name
    end
  end


  # TODO: deprecated
  # this combines the taxon names from type_specimens with 
  # the type_taxon_names (until we merge the two)
  def all_type_taxon_names # :yields: String
    (type_taxon_names + type_specimen_taxon_names).uniq.sort{|a,b| a.l <=> b.l }
  end

  def self.for_visible_taxon_names(proj) # :yields: Array of Repositories
     Repository.find_by_sql(["SELECT DISTINCT r.id, r.coden, r.name, r.url
       FROM taxon_names AS tn INNER JOIN repositories AS r ON tn.type_repository_id = r.id
       WHERE #{proj.sql_for_taxon_names} ORDER BY r.coden;" ])
  end
  
  
end
