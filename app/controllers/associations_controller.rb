class AssociationsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list
    @association_pages, @associations = paginate :associations, :per_page => 30,
      :conditions => ['proj_id = (?)', @proj.id] #   :order_by => 'display_name',
  end

  def show
    @association = Association.find(params[:id])
    @supports = @association.association_supports 
  end

  def new
    @association = Association.new
    @part1 = AssociationPart.new
    @part2 = AssociationPart.new
    @part1.otu = Otu.find(params[:otu_id]) if !params[:otu_id].blank?
  end

  def create  
    @association = Association.new(params[:association])

    ## see model for validation issues here (turned off now)
    @association.association_parts << AssociationPart.new(params[:part1])
    @association.association_parts << AssociationPart.new(params[:part])

    if @association.save
     flash[:notice] = 'Association was successfully created.'
      redirect_to :action => 'edit', :id => @association
    else
      render :action => 'new'
    end
  end

  def edit
    @association = Association.find(params[:id])
    @new_part = AssociationPart.new
  end

  def update
    @association = Association.find(params[:id])
    
    # decide whether to add a part?
    unless params[:part][:otu_id].empty?
      @new_part = AssociationPart.new(params[:part])
      @association.association_parts << @new_part
    end
  
    # can update notes without adding parts
    if @association.update_attributes(params[:association])
     flash[:notice] = 'Association was successfully updated.'
      redirect_to :action => 'edit', :id => @association
    else
      @association.association_parts(true) # reloads from the database so we don't try to display invalid part
      render :action  => 'edit'
    end
  end

  def destroy
    Association.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def destroy_part
    @association = Association.find(params[:id])
    @association.association_parts.last.destroy
    redirect_to :action => 'edit', :id => @association
  end
 
  def list_supporting_refs
    @refs = Ref.find_by_sql( ["SELECT DISTINCT refs.*
    FROM associations INNER JOIN (refs INNER JOIN association_supports ON refs.id = association_supports.ref_id) ON associations.id = association_supports.association_id
    WHERE ( (refs.id Is Not Null) and (associations.proj_id = ?)) ORDER BY refs.full_citation;", @proj.id ]) 
    
    render :action => 'list_supporting_refs' ## should probably unify the refs list view for public consumption?
  end

  def list_associations_by_confidence
    @confidences  = Confidence.find_all_by_proj_id(@proj.id, :order => "position ASC")
    render :action => 'list_associations_by_confidence' ## should probably unify the refs list view for public consumption?
  end
  
  def list_associations_by_object_relationship
    @object_relationships  = ObjectRelationship.find_all_by_proj_id(@proj.id)
    render :action => 'list_associations_by_object_relationship' ## should probably unify the refs list view for public consumption?
  end
  
  def list_associations_by_otu ## need to alphabetize here
    @otus  = Otu.find_by_sql( ["SELECT DISTINCT association_parts.otu_id
                                FROM association_parts INNER JOIN associations ON association_parts.id = associations.id
                                WHERE (((associations.proj_id)= ? ));", @proj.id])    

    render :action => 'list_associations_by_otu' ## should probably unify the refs list view for public consumption?
  end
  
  def association_tree ## is this used?
    @otus = Otu.find_by_sql(["SELECT o.*, t.name as tn, t.id as tnid, t.iczn_group as taxon_iczn_group FROM otus o 
    LEFT JOIN taxon_names t ON t.id = o.taxon_name_id
    LEFT JOIN otu_groups_otus og on o.id = og.otu_id
    WHERE o.proj_id = ? and og.otu_group_id = ? AND t.id is not null
    GROUP BY t.id ORDER BY t.l, o.name", @proj.id, 25])
    @tns = TaxonName.find_by_id(322).children
  end
 
  # TODO: mx3 - Make all browse_by parameter based to browse

  def browse
    @show = ['browse_default']
    session['association_view'] = 'default'
    @no_right_column = true
  end
  
  def browse_confidences
    @show = ['browse_confidences']
    session['association_view'] = 'browse_confidences'
    @confidences = Confidence.find_by_sql(["SELECT DISTINCT c.id, c.proj_id, Count(a_s.association_id) AS count, c.name, c.short_name
                  FROM confidences AS c INNER JOIN association_supports AS a_s ON c.id = a_s.confidence_id
                  GROUP BY c.id, c.proj_id, c.name
                  HAVING (((c.proj_id)= ?)) ORDER BY position;", @proj.id])

    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_unsupported ## NOT DONE
    @show = ['browse_list_associations']
    session['association_view'] = 'browse_unsupported'
    @associations = Association.find_by_sql(["SELECT DISTINCT a.id, a.proj_id
      FROM association_supports AS a_s RIGHT JOIN associations AS a ON a_s.association_id = a.id
      WHERE (((a_s.id) Is Null) AND ((a.proj_id)= ?));", @proj.id])
    @header = "Associations with no association support (attached references or specimens)."
    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_objectrelationships
    @show = ['browse_object_relationships']
    session['association_view'] = 'browse_object_relationships'
 
    @object_relationships = ObjectRelationship.find_by_sql(["SELECT DISTINCT c.id, c.proj_id, Count(a_p.association_id) AS count, c.interaction, c.complement, c.notes
                  FROM objectrelationships AS c INNER JOIN association_parts AS a_p ON c.id = a_p.object_relationship_id
                  GROUP BY c.id, c.proj_id 
                  HAVING (c.proj_id = ?) ORDER BY c.position;", @proj.id])   
    @no_right_col = true 
    render :action => 'browse' 
  end
 
  def browse_taxon_names # returns all the children of params['taxon_name'][:id] that are tied to Associations 
    if  params[:taxon_name] == nil 
      @taxon_names = ('') 
    else     
      @tn = TaxonName.find(params[:taxon_name][:id])
      og = nil  
      og ||= params[:otu_group][:id] if params[:otu_group]
    
      @taxon_names = Association.taxon_names(@tn, @proj.id, og)
      
   end
    @view_type = params[:view_type] || 'browse_taxon_names_table2'
    @show = ['browse_taxon_names']
    session['association_view'] = 'browse_taxon_names'
    render :action => 'browse' 
  end  
  
  def browse_untied 
    @show = ['browse_untied']
    @associations = Association.no_taxon_name(@proj.id)
    @otus = Association.untied_otus(@proj.id)
    @taxon_names = Association.untied_taxon_names(@proj.id)   
    session['association_view'] = 'browse_untied' 
    render :action => 'browse' 
  end
 
  def browse_negatives 
    @show = ['browse_list_associations']
    @associations = Association.negatively_supported(@proj.id)
    session['association_view'] = 'browse_negatives' 
    @header = "Associations with negative support (e.g. published misidentifications, failed lab trials)."
    render :action => 'browse' 
  end
    
  def browse_otus ## needs work (find all familes by OTU group, and arrange that way)
    @show = ['browse_otus']
    session['association_view'] = 'browse_otus'

    if params['otu_group']  
      og ||= params['otu_group'][:id]
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
    @show = ['browse_refs']
    session['association_view'] = 'browse_refs' 
    
    @refs = Association.unique_refs(@proj.id)
    
    @no_right_col = true 
    render :action => 'browse'
  end
  
  def browse_chronological
    @show = ['browse_chronological']
    session['association_view'] = 'browse_chronological' 
    @refs = Association.count_by_year(@proj.id)
    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_by_otu
    @show = ['browse_list_associations']
    session['association_view'] = 'browse_by_otu'
    @obj = Otu.find(params[:id]) 
    @header = "OTU name: " + @obj.display_name
    @associations = Association.by_otu(params[:id], @proj.id) 
    render :action => 'browse' 
  end
  
  def browse_by_taxon_name
    @show = ['browse_list_associations']
    session['association_view'] = 'browse_list_associations'
    @obj = TaxonName.find(params[:id])
    if params['include_children']
      @associations = Association.by_taxon_name_with_children(@obj, @proj.id)
    else
      @associations = Association.by_taxon_name(@obj, @proj.id)    
    end
    @header = "Taxon name: " + @obj.display_name + ( params['include_children'] ? " <i>and children </i>" : '')
    render :action => 'browse'
  end

  def browse_by_year
    @show = ['browse_list_associations']
    session['association_view'] = 'browse_by_year' 
    @header = "Year #{params['year']}."
    @associations = Association.by_year(params['year'], @proj.id)
    @no_right_col = true 
    render :action => 'browse' 
  end
  
  def browse_by_ref
    @show = ['browse_list_associations']
    session['association_view'] = 'browse_by_ref'
    @ref = Ref.find(params[:id])
    @header = "Reference: " + @ref.display_name  +  (@public == true ? "" : " (id: #{@ref.id})")
    @no_right_col = true 
    @associations = Association.by_ref(@proj.id, @ref.id) 
    render :action  => 'browse'
  end

  def browse_by_object_relationship 
    @show = ['browse_list_associations']
    session['association_view'] = 'browse_by_object_relationship'
    @object_relationship = ObjectRelationship.find(params['object_relationship_id'])
    @header = "Relationship: " + @object_relationship.display_name 
    @associations = Association.by_object_relationship(@object_relationship.id, @proj.id)  
    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_by_confidence
    @show = ['browse_list_associations']
    session['association_view'] = 'browse_by_confidence'
    @confidence = Confidence.find(params['confidence_id'])
    @header = "Confidence level: " + @confidence.display_name 
    @associations = Association.by_confidence(@confidence.id, @proj.id)  
    @no_right_col = true 
    render :action => 'browse' 
  end

  def browse_show
    @show = ['browse_show']
    session['association_view'] = 'browse_show'
    @association = Association.find(params[:id])
    @supports = @association.association_supports 
    @no_right_col = true
    render :action => 'browse' 
  end
end
