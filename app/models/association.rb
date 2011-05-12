# == Schema Information
# Schema version: 20090930163041
#
# Table name: associations
#
#  id         :integer(4)      not null, primary key
#  notes      :text
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

class Association < ActiveRecord::Base
  has_standard_fields
  
  include ModelExtensions::Taggable
  include ModelExtensions::DefaultNamedScopes

  has_many :association_parts, :order => "position", :dependent => :destroy
  has_many :association_supports,  :include => :confidence, :order => "confidences.position", :dependent => :destroy

  def display_name(options = {}) # :yields: String
    opt = {
      :type => nil
    }.merge!(options.symbolize_keys)
    s = ''
    i = 0
    case opt[:type]
    when :selected
      s = self.display_name(:type => :for_select_list)
    when :for_select_list
      for part in self.association_parts
        if part.object_relationship
          s <<  " (" + (part.object_relationship.complement? ? part.object_relationship.complement : part.object_relationship.interaction) + ") "
        end
        s << part.otu.display_name
      end
    when :short_display_name # TODO Resolve
      for part in self.association_parts[1..self.association_parts.size]
        if part.object_relationship
          s << " [" + (part.object_relationship.complement? ? part.object_relationship.complement : part.object_relationship.interaction) + " / " + (part.object_relationship.complement? ? part.object_relationship.interaction : part.object_relationship.complement) + "] "
        end
        s << part.otu.display_name + (part.otu.taxon_name_id? ? ( " (" + part.otu.taxon_name.name_at_rank('family') + ") ") : "")
        i += 1
      end
    when :short_display_name_first_relationship 
      s = self.association_parts[1].object_relationship.display_name
    when :short_display_name_first_family # TODO Resolve
      s = self.association_parts[1].otu.taxon_name_id? ?   self.association_parts[1].otu.taxon_name.name_at_rank('family') : 'No taxon name attached'
    else
      for part in self.association_parts
        if part.object_relationship
          s << " [" + (part.object_relationship.complement? ? part.object_relationship.complement : part.object_relationship.interaction) + " / " + (part.object_relationship.complement? ? part.object_relationship.interaction : part.object_relationship.complement) + "] "
        end
        s << part.otu.display_name + ((i > 0) && part.otu.taxon_name_id? ? ( " (" + part.otu.taxon_name.name_at_rank('family') + ") ") : "")
        i += 1
      end
    end
    s
  end
  
  def supporting_refs
    self.association_supports.collect{|s| s.ref if (s.class == RefSupport)}
  end
  
  # lots of ugly MySQL statements, can likely be abstracted more cleanly once the taxonomic heirachy linking is better sorted out
  def self.by_otu(otu_id, proj_id) 
    @associations = Association.find_by_sql(["SELECT associations.*
      FROM otus INNER JOIN (associations INNER JOIN association_parts ON associations.id = association_parts.association_id) ON otus.id = association_parts.otu_id
      WHERE (((otus.id)= ? ) and (associations.proj_id = ? ) );", otu_id, proj_id]) 
  end

  def self.by_taxon_name(tn, proj_id)  # tn is a TaxonName object
    @associations = Association.find_by_sql(["SELECT associations.*
      FROM otus INNER JOIN (associations INNER JOIN association_parts ON associations.id = association_parts.association_id) ON otus.id = association_parts.otu_id
      WHERE (((otus.taxon_name_id) = ? ) and (associations.proj_id = ? )) ORDER BY otus.name;", tn.id, proj_id]) 
  end
  
  def self.by_taxon_name_with_children(tn, proj_id, og = nil) # tn is a TaxonName object, og is an otu_group id
    s = ''
    s = " AND ((og.otu_group_id) = #{og}) " if og 
    @associations = Association.find_by_sql(["SELECT DISTINCT aps.association_id as id
    FROM (taxon_names AS tn INNER JOIN (otu_groups_otus AS og INNER JOIN otus ON og.otu_id = otus.id) ON tn.id = otus.taxon_name_id) INNER JOIN association_parts AS aps ON otus.id = aps.otu_id 
    WHERE (((tn.l) >= #{tn.l} ) AND ((tn.r) <= #{tn.r} ) #{s} AND ((otus.proj_id) = ?)) ORDER BY tn.l;", proj_id])  
  end

  def self.taxon_names(tn, proj_id, og = nil)  # tn is a TaxonName object, og is an otu_group id
    s = ''
    s = " AND ((og.otu_group_id) = #{og}) " if og 
    @taxon_names = TaxonName.find_by_sql(["SELECT DISTINCT tn.*, og.otu_group_id, otus.proj_id
      FROM (taxon_names AS tn LEFT JOIN (otu_groups_otus AS og LEFT JOIN otus ON og.otu_id = otus.id) ON tn.id = otus.taxon_name_id) LEFT JOIN association_parts AS aps ON otus.id = aps.otu_id
      WHERE (((tn.l) >= #{tn.l} ) AND ((tn.r) <= #{tn.r} ) #{s} AND ((otus.proj_id) = ?)) ORDER BY tn.l;", proj_id]) 
  end
 
  def self.no_taxon_name(proj_id) # returns an list of associations with no taxon names
    # we can greatly limit those to test fully by the following query where
    # we assume that we only need to test associations that have 2 or more otus without taxon names
    @test = Association.find_by_sql(["
    SELECT DISTINCT associations.id, otus.taxon_name_id, Count(association_parts.association_id) AS CountOfassociation_id, associations.proj_id
      FROM associations INNER JOIN (association_parts INNER JOIN otus ON association_parts.otu_id = otus.id) ON associations.id = association_parts.association_id
      GROUP BY associations.id, otus.taxon_name_id, associations.proj_id
      HAVING (((otus.taxon_name_id) Is Null) AND ((Count(association_parts.association_id))>1) AND ((associations.proj_id)= ? ));", proj_id]) 
    @result = []
    for t in @test
      assoc = Association.find(t.id)
      pass = 0 
      for p in assoc.association_parts
        if not p.otu.taxon_name_id ==  nil
          pass = 1
        end
      end
      @result.push assoc if pass == 0
    end 
    @result 
  end

  # return tns tied to otus not used in an association, this can return many results on projects that aren't association specific
  def self.untied_taxon_names(proj_id) 
    TaxonName.find_by_sql(["SELECT ap.id, o.proj_id, o.id as otu_id, tn.*
      FROM (otus AS o INNER JOIN taxon_names AS tn ON o.taxon_name_id = tn.id) LEFT JOIN association_parts AS ap ON o.id = ap.otu_id
      WHERE (((ap.id) Is Null) AND ((o.proj_id)=4));", proj_id])
  end
  
  # return otus used in an association but without a tn, this can return many results on projects that aren't association specific
  def self.untied_otus(proj_id)  
    @otus = Otu.find_by_sql(["SELECT DISTINCT otus.id, otus.name, associations.proj_id
      FROM (association_parts INNER JOIN otus ON association_parts.otu_id = otus.id) INNER JOIN associations ON association_parts.association_id = associations.id
      WHERE (((otus.taxon_name_id) Is Null) AND ((associations.proj_id)= ?)) ORDER BY otus.name;", proj_id])
  end
 
  def self.negatively_supported(proj_id)  
    Association.find_by_sql([" SELECT DISTINCT a_s.negative, a.id, a.proj_id
      FROM association_supports AS a_s INNER JOIN associations AS a ON a_s.association_id = a.id
      WHERE (((a_s.negative)= True ) AND ((a.proj_id)= ?));", proj_id])
  end
  
  def self.count_by_year(proj_id) # aliasing tables a bad idea for HAVING + MySQL
    Ref.find_by_sql(["SELECT refs.year, Count(associations.id) AS count, associations.proj_id, association_supports.type
      FROM associations INNER JOIN (association_supports INNER JOIN refs ON association_supports.ref_id = refs.id) ON associations.id = association_supports.association_id
      GROUP BY refs.year, association_supports.type, associations.proj_id
      HAVING (((association_supports.type)='RefSupport') AND ((associations.proj_id)= ?));", proj_id])
  end
    
  def self.unique_refs(proj_id) # joins to assoc necessary for proj_id
    Ref.find_by_sql( ["SELECT DISTINCT refs.*, Count(association_supports.association_id) AS count, associations.proj_id
    FROM (refs INNER JOIN association_supports ON refs.id = association_supports.ref_id) INNER JOIN associations ON association_supports.association_id = associations.id
    GROUP BY refs.id, associations.proj_id
    HAVING (associations.proj_id = ?) ORDER BY refs.cached_display_name;", proj_id])    
  end
 
  def self.by_ref(proj_id, ref_id)
    Association.find_by_sql(["SELECT assoc.id as id, assoc.proj_id, refs.cached_display_name, refs.id as ref_id,  o.name, ap.position
     FROM (association_parts AS ap INNER JOIN ((association_supports AS as_sup INNER JOIN refs ON as_sup.ref_id = refs.id) INNER JOIN associations AS assoc ON as_sup.association_id = assoc.id) ON ap.association_id = assoc.id) INNER JOIN otus AS o ON ap.otu_id = o.id
     WHERE ((assoc.proj_id = ?) and (refs.id = ?) AND ((ap.position) = 1)) ORDER BY o.name;",  proj_id, ref_id ]) 
  end
  
  def self.by_year(year, proj_id)
    Association.find_by_sql(["SELECT DISTINCT r.year, a.proj_id, a.id
      FROM associations AS a INNER JOIN (association_supports AS ass INNER JOIN refs AS r ON ass.ref_id = r.id) ON a.id = ass.association_id
      WHERE (((r.year)= ?) AND ((a.proj_id)= ?) AND ((ass.type)='RefSupport'));", year, proj_id ])
  end
  
  def self.by_object_relationship(object_relationship_id, proj_id)
    Association.find_by_sql([ "SELECT DISTINCT a.proj_id, association_parts.object_relationship_id, a.id
      FROM association_parts INNER JOIN associations AS a ON association_parts.association_id = a.id
      WHERE (((a.proj_id)= ?) AND ((association_parts.object_relationship_id)= ?));", proj_id,  object_relationship_id])
  end

  def self.by_confidence(confidence_id, proj_id)
    Association.find_by_sql([
        "SELECT DISTINCT c.id, a.proj_id, a.id
      FROM associations AS a INNER JOIN (association_supports AS a_s INNER JOIN confidences AS c ON a_s.confidence_id = c.id) ON a.id = a_s.association_id
      WHERE (((c.id)= ?) AND ((a.proj_id)= ?));", confidence_id, proj_id])
  end

  
  protected
  # def validate
  #   others = find_others
  #   others.each{ |o|
  #     if compare_parts(o.association_parts, association_parts)
  #       errors.add(:base, "Another association exists that is the same as this.")
  #       break
  #     end
  #   }
  # end
  
  def find_others
    if self[:id]
      return self.class.find(:all, :include => :association_parts, :condition => ["id != ?", id])
    else
      return self.class.find(:all, :include => :association_parts)
    end
  end
  
  # def compare_parts(parts1, parts2)
  #   # first test if they have the same number of parts
  #   return false if parts1.size != parts2.size
  #
  #   # they are the same size...
  #   for i in 0..(parts1.size)
  #     a = parts1[i]
  #     b = parts2[i]
  #     if not (a.position == b.position and a.object_relationship_id == b.object_relationship_id and a.object_relationship.complement == b.object_relationship.complement and a.otu_id == b.otu_id)
  #       return false
  #     end
  #   end
  #   return true
  # end
     
end
