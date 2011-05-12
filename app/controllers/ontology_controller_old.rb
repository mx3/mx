class OntologyOldController < ApplicationController

  # This controller is a little different, as it unifies a number of mx components to a single
  # "application".  Caution should be used in integrating it with the other aspects of mx.

  # Ontologies in mx make use of Isas, Parts, Tags (+ Keywords), and Figures.

  verify :method => :post, :only => [ :destroy_term, :destroy_relationship, :create, :update ], :redirect_to => { :action => :index }

  # OBO file batch loading 
  def batch_OBO
  end

  # TODO: move to model
  def batch_verify_OBO
     if params[:temp_file][:file].blank?
       flash[:notice] = "Choose a text file with your terms in it before verifying!"
       redirect_to(:action => :batch_load) and return  
     end
     
    @taxon_name = TaxonName.find(params[:term][:taxon_name_id]) if params[:term] and !params[:term][:taxon_name_id].blank?
    @ref = Ref.find(params[:term][:ref_id]) if params[:term] and !params[:term][:ref_id].blank?
    @part_for_isa = Part.find(params[:term][:part_id_for_is_a]) if params[:term] and !params[:term][:part_id_for_is_a].blank?
    @isa = Isa.find(params[:term][:isa_id]) if params[:term] and !params[:term][:isa_id].blank?
   
    @terms = OntologyController::Terms.new
    
    # detect OBO files
    @f = params[:temp_file][:file].read
        begin
         @of = Ontology.terms_from_obo(:file => @f, :proj_id => @proj.id)
       rescue OboFile::ParseError => e
        flash[:notice] = "Error loading file: #{e}"
        redirect_to :action => :batch_load and return
       end

      terms = of.term_hash # hash of key->value pairs with word->dbxref
   
    for t in term s.keys do
      if @t = Part.find_by_name_and_proj_id(t, @proj.id)
        w = OntologyController::Terms::Term.new(@t)
        w.dbxref = terms[t]
        @terms.existing.push(w) 
      else
        w = OntologyController::Terms::Term.new(t)
        w.dbxref = terms[t]
        @terms.not_present.push(w) 
      end
    end

    @inc_dbxref = true if params[:OBO_inc_dbxref]
    @compare = true if params[:OBO_compare] 
  end

  # TODO: move to model (this is semi-deprecated)
  def batch_verify
     if params[:temp_file][:file].blank?
       flash[:notice] = "Choose a text file with your terms in it before verifying!"
       redirect_to(:action => :batch_load) and return  
     end
     
    @taxon_name = TaxonName.find(params[:term][:taxon_name_id]) if params[:term] and !params[:term][:taxon_name_id].blank?
    @ref = Ref.find(params[:term][:ref_id]) if params[:term] and !params[:term][:ref_id].blank?
    @part_for_isa = Part.find(params[:term][:part_id_for_is_a]) if params[:term] and !params[:term][:part_id_for_is_a].blank?
    @isa = Isa.find(params[:term][:isa_id]) if params[:term] and !params[:term][:isa_id].blank?
   
    @terms = OntologyController::Terms.new
    
    # detect OBO files
    @f = params[:temp_file][:file].read
    if @f =~ /format-version/ && @f =~ /id:/ # we assume its a OBO file, a weak check for now
       begin
          of = Ontology.terms_from_obo(@f)
       rescue OboFile::ParseError => e
        flash[:notice] = "Error loading file: #{e}"
        redirect_to :action => :batch_load and return
       end

      terms = of.term_hash # hash of key->value pairs with word->dbxref
    else
      turms = @f.split(/\n{1,}/).map {|x| x.strip} # read the contents of the uploaded file
      terms = turms.inject({}) {|sum, t| sum.update(t => nil)} # point the has to nil, no dbxref here 
    end

    for t in terms.keys do
      if @t = Part.find_by_name_and_proj_id(t, @proj.id)
        w = OntologyController::Terms::Term.new(@t)
        w.dbxref = terms[t]
        @terms.existing.push(w) 
      else
        w = OntologyController::Terms::Term.new(t)
        w.dbxref = terms[t]
        @terms.not_present.push(w) 
      end
    end

    @inc_dbxref = true if params[:OBO_inc_dbxref]
    @compare = true if params[:OBO_compare] 
  end

  # TODO: what does this do now?
  def batch_update
    _batch_update_vars # see private
    begin
      Part.transaction do
        for p in params[:part].keys
          if params[:check][p]
            prt = Part.find(p)
             
            prt.obo_dbxref = params[:dbxref][p] if params[:dbxref] && params[:dbxref][p]
            prt.taxon_name = @tn if @tn
            prt.ref = @ref if @ref
            prt.save!
            
            if @isa && @part_for_isa
              @relationship = Ontology.new(:part1_id => prt.id, :part2_id => @part_for_isa.id, :isa_id => @isa.id )
              @relationship.save!
            end
            
            @count += 1
          end
        end
      end

    rescue ActiveRecord::RecordInvalid => e
      flash[:notice] = "Update failed: #{e}."
      redirect_to :action => :batch_load and return
    end
     
    flash[:notice] = "Successfully updated #{@count} terms." 
    redirect_to :action => :batch_load
  end


  def list_latest
    @terms = @proj.parts.recently_changed(1.weeks.ago).ordered_by_updated_on.ordered_by_name # find(:all, :order => 'parts.created_on DESC, parts.updated_on DESC, parts.name') 
    render :file => 'ontology/list_terms',:use_full_path => true, :layout => true
  end
  
  def list_terms_by_def
    if request.post?
     if params[:search_string].blank?
      flash[:notice] = "Include a search string." 
      redirect_to :action => :list_terms_by_def and return
     end
      @terms = @proj.parts.with_description_containing(params[:search_string]).ordered_by_name
      render :file => 'ontology/list_terms',:use_full_path => true, :layout => true and return
    end
  end

  def fragment_search
    if request.post?
     if params[:search_string].blank?
      flash[:notice] = "Include a search string." 
      redirect_to :action => :fragment_search and return
     end
      @terms = @proj.parts.by_fragment(params[:search_string]).ordered_by_name

      render :update do |page|
        page.replace_html :term_list, :partial => "list"
      end and return
    else
      @terms = []
    end
  end

  # TODO: before filter this
  def admin
    if (session[:person].is_admin || session[:person].is_ontology_admin) && !@proj.ontology_namespace.blank?
      @result = {:obsoleted => [], :synonyms_with_xrefs => []}
      @result.merge!(:synonyms_with_xrefs => @proj.parts.synonyms(@proj.id).with_dbxref_status(true).ordered_by_name)
      @result.merge!(:obsoleted => @proj.parts.obsolete(@proj.id).ordered_by_name)
      @result.merge!(:synonyms_requiring_obsolete_tag => (@result[:synonyms_with_xrefs] - @result[:obsoleted]))
    
      @result.merge!(:terms_requiring_xrefs =>  (@proj.ontology_restricted_parts(:included) - @proj.parts.with_dbxref_status(true).ordered_by_name))
      
      @result.merge!(:terms_with_xrefs_AND_candidacy_tags => (@proj.ontology_restricted_parts(:included) & @proj.parts.with_dbxref_status(true).ordered_by_name)) 
      @result.merge!(:terms_with_synonym_tags_with_internal_namespace => @proj.tags.by_class("Part").by_keyword(@proj.synonym_keyword).with_referenced_object_not_starting_with("#{@proj.ontology_namespace}:").collect{|t| t.tagged_obj}.uniq)
    else
      flash[:notice] = "Curious, it doesn't appear you are an admin, or you have not created a namespace for this project."
      redirect_to :action => :index and return
    end
  end
 
  # TODO: before filter this
  def _admin_update_parts_with_xrefs
    if !Person.find($person_id).is_admin? 
      flash[:notice] = "Curious, it doesn't appear you are an admin."
      redirect_to :action => :index and return
    end
   
    Part.fill_blank_xrefs(:padding => 7,
                          :parts => (@proj.ontology_restricted_parts(:included) - @proj.parts.with_dbxref_status(true).ordered_by_name),
                          :proj_id => @proj.id,
                          :prefix => @proj.ontology_namespace)

    # need some way to strip candidate tags here as well 
    flash[:notice] = "Update attempted, if the terms requiring xrefs list is blank it was sucessful."
    redirect_to :action => :admin 
  end

  def _admin_strip_candidacy_tags_from_xrefed_terms
    if !Person.find($person_id).is_admin? 
      flash[:notice] = "Curious, it doesn't appear you are an admin."
      redirect_to :action => :index and return
    end
    
    Part.strip_candidacy_tags(:parts => (@proj.ontology_restricted_parts(:included) & @proj.parts.with_dbxref_status(true).ordered_by_name), :proj_id => @proj.id)
    flash[:notice] = "Update attempted"
    redirect_to :action => :admin 
  end

  def _admin_update_internal_references_to_ontology_namespace
    if !Person.find($person_id).is_admin? 
      flash[:notice] = "Curious, it doesn't appear you are an admin."
      redirect_to :action => :index and return
    end

    redirect_to :action => :admin 
    begin 
      Ontology.transaction do  
      @proj.tags.by_class("Part").by_keyword(@proj.synonym_keyword).with_referenced_object_not_starting_with("#{@proj.ontology_namespace}:").uniq.each do |t|
        t.update_to_ontology_namespace
     end
      end
    rescue Exception => e
      flash[:notice] = "#{e}" 
      return      
    end
    flash[:notice] = "Updated"
  end

  def list_terms_by_restriction_keywords
    @title = "Terms by inclusion and exclusion tags"
    @result = {}
    @result.merge!(:excluded_parts => @proj.ontology_restricted_parts(:excluded), :explicitly_included_parts => @proj.ontology_restricted_parts(:included))
    render :file => 'shared/result_list', :use_full_path => true, :layout => true 
  end

  def list_untreated 
    @excluded = @proj.ontology_restricted_parts(:excluded)
    @included = @proj.ontology_restricted_parts(:included)
    @terms = (@proj.parts - (@included  + @excluded + @proj.parts.with_complete_dbxref(@proj.ontology_namespace).ordered_by_name)).sort{|a,b| a.name <=> b.name}
  end

  # filter functions, by Keywords through Tags
  def filter
    @keywords = @proj.keywords.used_in_a_tag
  end

  # AJAX only
  def _remove_kw_from_filter_form
    @keyword = Keyword.find(params[:id]) 
    render :update do |page|
      # remove it from the form
      page.remove "kwf_#{@keyword.id}"
      # add it back to the list here 
      page.insert_html :bottom, :keyword_list, :partial => "filter_kw_for_list_item", :object => @keyword 
     
      flash.discard
    end and return  
  end

  # AJAX only
  def _update_filter_results
    @keyword = Keyword.find(params[:id].split("_")[1]) 
    @parts = Part.tagged_with_keywords(:proj_id => $proj_id, :keywords => [@keyword ] )
    render :update do |page|
    
      # pop the keyword onto into the form
      page.insert_html  :bottom, :filter_form, :partial => "filter_kw_form_item" 
     
      # remove the keyword from the list
      page.remove "kwl_#{@keyword.id}"

      # update the results to that part
      page.replace_html :filter_header, :partial => "filter_kw_result_header_item", :collection => [@keyword]

      if @parts
        page.replace_html :filter_results, :partial => "filter_part_list_item", :collection => @parts, :spacer_template => "filter_list_divider"
      else
        page.replace_html :filter_results, :text => '<i>none</i>'
      end

      flash.discard
    end and return  
  end

  def _filter_search
    @keywords = []
   
    params[:words] && params[:words].keys.each do |k|
      @keywords.push Keyword.find(params[:words][k])
    end

    @parts = Part.tagged_with_keywords(params.update(:proj_id => $proj_id, :keywords => @keywords) )
    
    render :update do |page|
      # update the results header
      page.replace_html :filter_header, :partial => "filter_kw_result_header_item", :collection => @keywords
      # update the list
      if @parts
        page.replace_html :filter_results, :partial => "filter_part_list_item", :collection => @parts, :spacer_template => "filter_list_divider"
      else
        page.replace_html :filter_results, :text => '<i>none</i>'
      end
      flash.discard
    end and return  
  end

  def _populate_brief_form
    @parts = []
    params[:parts] && params[:parts].keys.each do |p|
      @parts.push Part.find(params[:parts][p])
    end

    # sort them here by name
    render :update do |page|
      # update the results header
      if @parts.size > 0
        page.replace_html :extended_results, :partial => "filter_small_form_item", :collection => @parts.sort{|a,b| a.display_name <=> b.display_name }
      else
        page.replace_html :extended_results, :text => '<i>none</i>'
      end  

      flash.discard
    end and return  
  end

  # end filter functions

  def list_terms_without_relationships
    @terms = @proj.parts.without_relationships.ordered_by_name
    render :file => 'ontology/list_terms', :use_full_path => true, :layout => true
  end
  
  def list_terms_without_xref
    @terms = @proj.parts.with_dbxref_status(nil).ordered_by_name
    render :file => 'ontology/list_terms', :use_full_path => true, :layout => true
  end

   def list_simple
    render :action => :list_simple and return if params[:kw].blank? || params[:kw][:id].blank? 
    respond_to do |format|
      format.html {
      }
      format.js {
        render :update do |page|
          page.replace_html :results, :partial => 'simple_tag', :locals => {:keyword => Keyword.find(params[:kw][:id]), :terms => @proj.parts.ordered_by_name}
        end and return
      }
     end      
  end

  def list_personal
    if request.post?
      @terms = Part.param_search(params.merge(:proj_id => @proj.id, :person_id => $person_id))
      render :partial => 'list'
    else 
     @terms = [] 
    end
  end 



  def _markup_definition
     if @term = Part.find(params[:id])
       if not @term.description
          render :text => '<i>no definition to markup</i>', :layout => false
        else
          @l = Linker.new(:proj_id => @proj.id, :incoming_text => @term.description, :adjacent_words_to_fuse => 5)
          render :text => @l.linked_text(:proj_id => @proj.id), :layout => false  
        end
     else
      flash[:notice] = "Something went wrong when trying to markup a definition."
      render :action => :index
    end
  end

  # TODO: move to RJS link_to_method
  def _unmarkup_definition
     if @term = Part.find(params[:id])
       if not @term.description
          render :text => '<i>no definition to markup</i>', :layout => false
        else
          render :text => @term.description
        end
     else
      flash[:notice] = "Something went wrong when trying to markup a definition."
      render :action => :index
    end
  end

  def proofer
    respond_to do |format|
      format.html {
        @text = nil
          if !params[:ref_id].blank? 
            # need to expand to any kind of incoming text
            if @ref = Ref.find(params[:ref_id])
              if @ref.ocr_text.blank?
                @text = "No text available."  
              else
                @text =  @ref.ocr_text # have to set this vs. partial rendering
              end 
                @l = Linker.new(:proj_id => @proj.id, :incoming_text => @text, :exclude_common_words => true, :adjacent_words_to_fuse => 5, :minimum_word_size => 3)
                @unmatched = @l.unmatched(:proj_id => @proj.id, :minimum_word_size => 3).reject{|w| w =~ /\d\d/} 
            end
          end
        }
        format.js {
          render :update do |page|
            @l = Linker.new(:proj_id => @proj.id, :adjacent_words_to_fuse => 5, :incoming_text => params[:txt].to_s, :exclude_common_words => (params[:exclude_common_words] || false))
            @unmatched = @l.unmatched(:proj_id => @proj.id, :minimum_word_size => 3).reject{|w| w =~ /\d\d/}
            @bioportal_id = params[:bioportal_id] 
            page.replace_html :proofed_text, :partial => 'proofed' 
          end and return
      }
    end
    @bioportal_id = params[:bioportal_id]            
  end

  def proofer_batch_create
    begin
      @count = Part.proofer_batch_create(params.merge(:proj_id => @proj.id))
    rescue Exception => e
      flash[:notice] = "Something went wrong: #{e}"
      render :action => :proofer and return
    end
    redirect_to :action => :list
  end

  def visualize
    @terms = @proj.parts(:include => [:tags, :figures, :primary_relationships])
    @no_right_col = true
  end

  def visualize2
    send_data(Part.visualize_svg(@proj.id), :type=>"image/svg+xml", :disposition =>"inline") 
  end

  
  def _add_relationship_from_cart
    @relationship = Ontology.new
    @relationship.part2_id = params[:part2_id]
    @relationship.part1_id = params[:id].split("_")[1]  
    @relationship.isa_id = params[:isa_id]

    begin
      Ontology.transaction do
        @relationship.save!
      end
    rescue Exception => e
      flash[:notice] = e.message
        render :update do |page|
          page.replace_html :relationship_cart_notice, "<span style='color: red;'>#{flash[:notice]}</span>"
          flash.discard
        end and return        
    end 
   
    render :update do |page|
      page.insert_html :bottom, :existing_relationships, :text => "<br/>added: #{@relationship.display_name}"
      page.replace_html :relationship_cart_notice, :text => "<span class='passed'>added relationship</span>" 
    end and return
  end

  def _populate_consituent_parts
    @cop = Part.find(params[:id]).logical_relatives(:direction => :children)       
    @cop ||= []
    render :update do |page|
      page.replace_html :constituent_parts, :partial => 'logical_part_list', :locals => {:children_of_part => @cop}
    end and return
  end

  # END tree based navigation
  
  # below = alpha tests

  def protovis_sunburst
    @isa = Isa.find(:first, :conditions => {:interaction => 'is_a', :proj_id => @proj.id})
    if !params[:id] .blank?
      @tree_root = Part.find(params[:id])
    else
      @tree_root = @proj.default_ontology_term
    end 
    render :layout => :false
  end

  def test
    @terms = @proj.parts[0..20]
    render :layout => false
  end

  def test2
    @treetop = @proj.default_ontology_term
  end
  
  def test3
    @tree_root = @proj.default_ontology_term
    render :layout => :false
  end

  def test4
    @isa = Isa.find(:first, :conditions => {:interaction => 'is_a', :proj_id => @proj.id})
    respond_to do |format|
      format.json {
        render :json => Part.find(params[:id]).js_flat_hash(:relationship_type => @isa.id).inject({}){|sum,o| sum.merge!(o.part1.id => o.part1.name) } # "1" # @foo
        #.split(/\s/).collect{|w| "<tspan x=\"0\" dy=\"1em\">#{w}</tspan>"}.join("") 
      }
    end
  end
 
  def test5
    @dot = Ontology.dot(:proj_id => @proj.id).output(:dot => String)
  end


  # END tests

  private

  def _batch_update_vars
    @count = 0
    params[:taxon_name_id] = params[:term][:taxon_name_id] if params[:term] && !params[:term][:taxon_name_id].blank? # handles batch loading from Proofer
    @tn = TaxonName.find(params[:taxon_name_id]) unless params[:taxon_name_id].blank?
    params[:ref_id] = params[:term][:ref_id] if params[:term] && !params[:term][:ref_id].blank? # handles batch loading from Proofer
    @ref = Ref.find(params[:ref_id]) unless params[:ref_id].blank?
    @part_for_isa = Part.find(params[:part_for_isa_id]) unless params[:part_for_isa_id].blank?
    @isa = Isa.find(params[:isa_id]) unless params[:isa_id].blank?
  end

end
