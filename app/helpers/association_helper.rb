# encoding: utf-8
module AssociationHelper
  def object_relationships_dd
    @proj.object_relationships.collect {|o| [ o.interaction + " [#{o.complement}]",   o.id ] } + 
    @proj.object_relationships.collect {|o| [ o.complement + " [#{o.interaction}]",  - o.id ] }
   end

  def no_taxon_name # returns an list of associations with no taxon names
    # we can greatly limit those to test by the following query:
    # we assume that we only need to test associations that have 2 or more otus without taxon names

    @test = Association.find_by_sql(["
SELECT DISTINCT associations.id, otus.taxon_name_id, Count(association_parts.association_id) AS CountOfassociation_id, associations.proj_id
FROM associations INNER JOIN (association_parts INNER JOIN otus ON association_parts.otu_id = otus.id) ON associations.id = association_parts.association_id
GROUP BY associations.id, otus.taxon_name_id, associations.proj_id
HAVING (((otus.taxon_name_id) Is Null) AND ((Count(association_parts.association_id))>1) AND ((associations.proj_id)= ? ));", @proj.id])
   
    @result = @test
    for t in @test
      pass = 0
      @parts = AssociationPart.find_by_association_id(t.id)
        for p in @parts
          if p.taxon_name != nil
            pass = 1
          end
        end
        @result << @p if pass == 0
      end 
    @result 
  end
 
   
end
