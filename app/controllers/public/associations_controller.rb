class Public::AssociationsController < Public::BaseController

  def index 
    redirect_to :action => 'browse'
  end
   
  def browse
    @show = ('browse_default')
    session['association_view'] = 'default'
    @no_right_col = true
  end
  
  def browse_confidences
    @show = ('browse_confidences')
    session['association_view'] = 'browse_confidences'
    @confidences = Confidence.find_by_sql(["SELECT DISTINCT c.id, c.proj_id, Count(a_s.association_id) AS count, c.name, c.short_name
                  FROM confidences AS c INNER JOIN association_supports AS a_s ON c.id = a_s.confidence_id
                  GROUP BY c.id, c.proj_id, c.name
                  HAVING (((c.proj_id)= ?)) ORDER BY position;", @proj.id])

    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_unsupported ## NOT DONE
    @show = ('browse_list_associations')
    session['association_view'] = 'browse_unsupported'
    @associations = Association.find_by_sql(["SELECT DISTINCT a.id, a.proj_id
      FROM association_supports AS a_s RIGHT JOIN associations AS a ON a_s.association_id = a.id
      WHERE (((a_s.id) Is Null) AND ((a.proj_id)= ?));", @proj.id])
    @header = "Associations with no association support (attached references or specimens)."
    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_object_relationships
    @show = ('browse_object_relationships')
    session['association_view'] = 'browse_object_relationships'
    
    @object_relationships = ObjectRelationship.find_by_sql(["SELECT DISTINCT c.id, c.proj_id, Count(a_p.association_id) AS count, c.interaction, c.complement, c.notes
                  FROM object_relationships AS c INNER JOIN association_parts AS a_p ON c.id = a_p.object_relationship_id
                  GROUP BY c.id, c.proj_id 
                  HAVING (c.proj_id = ?) ORDER BY c.position;", @proj.id])   
    @no_right_col = true 
    render :action => 'browse' 
  end
 
  def browse_taxon_names # returns all the children of params['taxon_name']['id'] that are tied to Associations 
    if  params['taxon_name'] == nil 
      @taxon_names = ('') 
    else     
      @tn = TaxonName.find(params['taxon_name']['id'])
      og = nil  
      og ||= params['otu_group']['id'] if params['otu_group']
    
      @taxon_names = Association.taxon_names(@tn, @proj.id, og)
   end
    @show = ('browse_taxon_names')
    session['association_view'] = 'browse_taxon_names'
    render :action => 'browse' 
  end  
  
  def browse_untied 
    @show = ('browse_untied')
    @associations = Association.no_taxon_name(@proj.id)
    @otus = Association.untied_otus(@proj.id)
    @taxon_names = Association.untied_taxon_names(@proj.id)   
    session['association_view'] = 'browse_untied' 
    render :action => 'browse' 
  end
 
  def browse_negatives 
    @show = ('browse_list_associations')
    @associations = Association.negatively_supported(@proj.id)
    session['association_view'] = 'browse_negatives' 
    @header = "Associations with negative support (e.g. published misidentifications, failed lab trials)."
    render :action => 'browse' 
  end
    
  def browse_otus ## needs work (find all familes by OTU group, and arrange that way)
    @show = ('browse_otus')
    session['association_view'] = 'browse_otus'

    if params['otu_group']  

      og ||= params['otu_group']['id']
      if og.to_i > 0
        if @otu_group = OtuGroup.find(og)
          @families = @proj.visible_families_by_otu_group(@otu_group.id) ## remove / fix me    
        end
      end  
    end
   
    @otus = ('')
    @otus = @otu_group.otus if @otu_group

    render :action => 'browse' 
  end
  
  def browse_refs
    @show = ('browse_refs')
    session['association_view'] = 'browse_refs' 
    
    @refs = Association.unique_refs(@proj.id)
    
    @no_right_col = true 
    render :action => :browse
  end
  
  def browse_chronological
    @show = ('browse_chronological')
    session['association_view'] = 'browse_chronological' 
    @refs = Association.count_by_year(@proj.id)
    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_by_otu
    @show = ('browse_list_associations')
    session['association_view'] = 'browse_by_otu'
    @obj = Otu.find(params[:id]) 
    @header = "OTU name: " + @obj.display_name
    @associations = Association.by_otu(params['id'], @proj.id) 
    render :action => 'browse' 
  end
  
  def browse_by_taxon_name
    @show = ('browse_list_associations')
    session['association_view'] = 'browse_list_associations'
    @obj = TaxonName.find(params['id'])
    if params[:include_children]
      @associations = Association.by_taxon_name_with_children(@obj, @proj.id)
    else
      @associations = Association.by_taxon_name(@obj, @proj.id)    
    end
    @header = "Taxon name: " + @obj.display_name + ( params['include_children'] ? " <i>and children </i>" : '')
    @no_right_col = true
    render :action => 'browse'
  end

  def browse_by_year
    @show = ('browse_list_associations')
    session['association_view'] = 'browse_by_year' 
    @header = "Year #{params['year']}."
    @associations = Association.by_year(params['year'], @proj.id)
    @no_right_col = true 
    render :action => 'browse' 
  end
  
  def browse_by_ref
    @show = ('browse_list_associations')
    session['association_view'] = 'browse_by_ref'
    @ref = Ref.find(params['id'])
    @header = "Reference: " + @ref.display_name  +  (@public == true ? "" : " (id: #{@ref.id})")
    @no_right_col = true 
    @associations = Association.by_ref(@proj.id, @ref.id) 
    render :action => 'browse'
  end

  def browse_by_object_relationship 
    @show = ('browse_list_associations')
    session['association_view'] = 'browse_by_object_relationship'
    @object_relationship = ObjectRelationship.find(params['object_relationship_id'])
    @header = "Relationship: " + @object_relationship.display_name 
    @associations = Association.by_object_relationship(@object_relationship.id, @proj.id)  
    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_by_confidence
    @show = ('browse_list_associations')
    session['association_view'] = 'browse_by_confidence'
    @confidence = Confidence.find(params['confidence_id'])
    @header = "Confidence level: " + @confidence.display_name 
    @associations = Association.by_confidence(@confidence.id, @proj.id)  
    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_show
    @show = ('browse_show')
  
    session['association_view'] = 'browse_show'
    @association = Association.find(params[:id])
    @supports = @association.association_supports # AssociationSupport.find(:all, :conditions => ["association_id = ?", @association.id], 
     #    :include => :confidence, :order => "confidences.position")
    @no_right_col = true
    render :action => 'browse' 
  end

end
