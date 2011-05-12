# == Schema Information
# Schema version: 20090930163041
#
# Table name: taxon_hists
#
#  id                   :integer(4)      not null, primary key
#  taxon_name_id        :integer(4)      not null
#  higher_id            :integer(4)
#  genus_id             :integer(4)
#  subgenus_id          :integer(4)
#  species_id           :integer(4)
#  subspecies_id        :integer(4)
#  author               :string(255)
#  year                 :string(6)
#  varietal_id          :integer(4)
#  varietal_usage       :string(24)
#  ref_id               :integer(4)
#  ref_page             :string(64)
#  taxon_name_status_id :integer(4)
#  notes                :text
#  creator_id           :integer(4)      not null
#  updator_id           :integer(4)      not null
#  updated_on           :timestamp       not null
#  created_on           :timestamp       not null
#

class TaxonHist < ActiveRecord::Base
  
  has_standard_fields
  has_many :tags, :as => :addressable, :dependent => :destroy, :include => [:keyword, :ref], :order => 'refs.cached_display_name ASC' 
  belongs_to :ref 
  
  belongs_to :taxon_name
  belongs_to :higher_taxon, :class_name => "TaxonName", :foreign_key => "higher_id"

  belongs_to :genus, :class_name => "TaxonName", :foreign_key => "genus_id"
  belongs_to :subgenus, :class_name => "TaxonName", :foreign_key => "subgenus_id"
  belongs_to :species, :class_name => "TaxonName", :foreign_key => "species_id"
  belongs_to :subspecies, :class_name => "TaxonName", :foreign_key => "subspecies_id"
  belongs_to :varietal, :class_name => "TaxonName", :foreign_key => "varietal_id"

  belongs_to :ref
  belongs_to :status, :class_name => "TaxonNameStatus", :foreign_key => "taxon_name_status_id"

  ## if higher_taxon_id is filled then none of the others should be filled

  validate :check_record
  def check_record
    if (not higher_id and not genus_id and not subgenus_id and not species_id and not subspecies_id and not varietal_id)
      errors.add(:higher_id, " (must select a higher taxon or one other name in combination)")
    end 

    if not taxon_name_id
      errors.add(:taxon_name_id, "need to attach to a taxon name")
      @in_taxon_hists = true
    end
  end

  def display_name(options = {})
    return higher_taxon.display_name if higher_taxon
    s = '<i>'
    s += "#{genus.name}" if genus_id
    s += " (#{subgenus.name})" if subgenus_id
    s += " #{species.name}" if species_id
    s += " #{subspecies.name}" if subspecies_id
    s += " </i> #{varietal_usage}<i>" if varietal_usage
    s += " #{varietal.name}" if varietal_id
    s += "</i>"

    if author
      if subspecies_id
        o = self.subspecies.orig_genus
        if o == genus.id
      s += " #{author}"              
        else
      s += " (#{author})"  
        end
        
      elsif species_id
        o = self.species.orig_genus
        if o == self.genus.id # throwing errors?  updated not sure if borks else
         s += " #{author}"  
        else
           s += " (#{author})"  
        end
      else
        s += " #{author}"
      end
    else
      s += " #{author}"
    end
    s += " #{year}" if year 
    s
  end


  def genus_group_id
    subgenus_id and return subgenus_id
    genus_id and return genus_id
    nil
  end

  def self.find_for_auto_complete(terms, conditions)
    case terms.size
    when 1
      search = sanitize_sql(["genus_taxon_hists.name LIKE ? OR
      species_taxon_hists.name LIKE ? OR taxon_hists.author LIKE ?",
      "#{terms[0]}%","#{terms[0]}%","#{terms[0]}%" ])
    when 2
      search = sanitize_sql(["(genus_taxon_hists.name LIKE ? AND species_taxon_hists.name LIKE ?) 
      OR (genus_taxon_hists.name LIKE ? AND taxon_hists.author LIKE ?) 
      OR (species_taxon_hists.name LIKE ? AND taxon_hists.author LIKE ?)",
      "#{terms[0]}%","#{terms[1]}%", "#{terms[0]}%","#{terms[1]}%", "#{terms[0]}%","#{terms[1]}%" ])
    when 3
      search = sanitize_sql(["genus_taxon_hists.name LIKE ? AND
      species_taxon_hists.name LIKE ? AND taxon_hists.author LIKE ?",
      "#{terms[0]}%","#{terms[1]}%","#{terms[2]}%" ])
    end

    conditions = "(#{conditions}) AND (#{search})"
    find(:all, :include => [:taxon_name, :genus, :species], :conditions => conditions, :limit => 20)    
  end

end


