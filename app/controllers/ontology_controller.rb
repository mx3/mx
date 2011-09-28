# this controller is for methods that span the ontology-related classes, there is no Ontology model

 require 'ontology/ontology_methods'
 require 'ontology/obo2mx'
 require 'rdf'
 require 'rdf/rdfxml'

# require 'ontology/batch_load/simple'
# require 'ontology/batch_load/obo'

class OntologyController < ApplicationController

  verify :method => :post, :only => [:create], :redirect_to => { :action => :index }

  def index
    # almost certainly not right
    @active_labels = @proj.labels.order('active_on DESC').limit(10).where(:active_on => 'NOT NULL') #    order_by_active_on # .limit('10')
  end

  def search
    if redirect = Ontology::OntologyMethods.search_redirect(params)
      redirect_to redirect
    else
      redirect_to(:action => 'index', :controller => 'ontology') and return
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
            @l = Linker.new(:proj_id => @proj.id, :incoming_text => @text, :exclude_common_words => true, :adjacent_words_to_fuse => 5, :minimum_word_size => 3, :link_url_base => self.request.host)
            @unmatched = @l.unmatched(:proj_id => @proj.id, :minimum_word_size => 3).reject{|w| w =~ /\d\d/} 
          end
        end
        render :action => 'ontology/proofer/index'
      }
      format.js {
        render :update do |page|
        @l = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.id, :adjacent_words_to_fuse => 5, :incoming_text => params[:txt].to_s, :exclude_common_words => (params[:exclude_common_words] || false))
        @unmatched = @l.unmatched(:proj_id => @proj.id, :minimum_word_size => 3).reject{|w| w =~ /\d\d/}
        page.replace_html :proofed_text, :partial => 'ontology/proofer/proofed' 
        end and return
      }
    end
  end

  def proofer_batch_create
    begin
      @count = Ontology::OntologyMethods.proofer_batch_create(params.merge(:proj_id => @proj.id))
    rescue Exception => e
      flash[:notice] = "Something went wrong: #{e}"
      render :action => 'ontology/proofer/index' and return
    end
    redirect_to :action => :list_by_active_on, :controller => :label
  end

 # Simple text-file import
 # def batch_simple
 # end

 #def batch_verify_simple
 #  if @result = Ontology::BatchLoad::Simple.batch_verify(:params => params, :proj => @proj)
 #    flash[:notice] = "Successfully parsed the file."
 #  else
 #    flash[:notice] = "Problem reading/parsing the input file."
 #    redirect_to :action => :batch_simple and return
 #  end      

 #  # TODO - move this to the result
 #  if !params[:tag][:keyword_id].blank? && @tag_keyword = Keyword.find(params[:tag][:keyword_id])
 #    @tag_ref = Ref.find(params[:tag][:ref_id]) if params[:tag] && !params[:tag][:ref_id].blank?
 #    @tag_notes = params[:tag][:notes]
 #    @tag_referenced_object = params[:tag][:referenced_object]
 #  end
 #end

 #def batch_create_simple
 #  if @count = Part.batch_create_simple(:params => params, :proj_id => @proj.id)
 #    flash[:notice] = "Successfully added #{@count} terms."
 #  else
 #    flash[:notice] = "Something went wrong during creation (often this due to a duplicate term), no terms added."
 #  end
 #  redirect_to :action => :list_latest
 #end

  def auto_complete_for_ontology
    if @result = Ontology::OntologyMethods.auto_complete_search_result(params.merge!(:proj_id => @proj.ontology_id_to_use))
      # TODO mx3: NEEDS REFACTORING - won't work with typical search
      render :json => Json::format_for_autocomplete_with_display_name(:entries => @result, :method => params[:method])
    else
      redirect_to(:action => 'index', :controller => 'ontology') and return
    end
  end

  # tree based navigation, TODO: move this to a separate controller?
  # it's recursive, and we keep track of a lot of metadata, so there is lots of :locals use
  def tree
    @treetop = @proj.default_ontology_class
    @proj.ontology_classes.first if !@treetop
    redirect_to :action => :new, :controller => :ontology_class and return if !@treetop 
    @colored_object_relationships = @proj.object_relationships.with_color_set
    @all_object_relationships = @proj.object_relationships 
    render :action => 'ontology/tree/index'
  end

  def _tree_set_root
    render :layout => false, :nothing => true and return if !params[:ontology_class]
    @treetop = OntologyClass.find(params[:ontology_class][:id])
    render :layout => false, :partial => 'ontology/tree/tree_index', :locals => { :relationship_type => ((params[:object_relationship] && params[:object_relationship][:id] && !params[:object_relationship][:id].blank?) ? params[:object_relationship][:id]  : 'all' ), :max_depth => (params[:max_depth].to_i || 2)}
  end 

  # open and close a node
  def _tree_navigate_through_child
    @ontology_class = OntologyClass.find_by_id(params[:id])
    
    @object_relationship = ObjectRelationship.find(params[:parent_relationship]) if !params[:parent_relationship].blank?
    @object_relationship == 'root' if !@object_relationship 
   
    # close 1 1;  open 0 1; open false (close); true (open) 
    render :update do |page|
      page.replace "level_#{@ontology_class.id}", :partial => 'ontology/tree/tree_recurser', :locals => {
        :level => (params[:close] ? 1 : 0),
        :max_depth => 1,
        :parent_node => @ontology_class,
        :open => (params[:close] ? false : true),
        :relationship => @object_relationship,
        :relationship_type => params[:relationship_type] }
    end and return        
  end

  def _tree_populate_target
    @ontology_class = OntologyClass.find_by_id(params[:id])
    @definition = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :is_public => true, :incoming_text => @ontology_class.definition, :adjacent_words_to_fuse => 5).linked_text
    render :update do |page|
       page.replace_html "ontology_tree_info_target", :partial => 'ontology_class/oc', :object => @ontology_class # :text => 'foo!' #:partial => "filter_small_form_item", :object => @ontology_class 
     #  page.replace_html "existing_relationships", :text => "<i>#{@part.relationships.size} existing relationships<i>" 
     #  page.replace_html "relationship_cart", :partial => 'relationship_cart', :locals => {:part2_id => @part.id, :isa => ((params[:relationship_type] == 'all' || params[:relationship_type].blank?) ?  @proj.isas.first :  Isa.find(params[:relationship_type])) }
     #  page.replace_html "unattached_parts", :partial => '/part/draggable_part', :collection => @proj.parts.without_relationships.ordered_by_updated_on
    end and return       
  end

  # targeting OBO v1.2 
  def show_OBO_file
    @time = Time.now()
    @relationships = @proj.object_relationships.reject{|r| Ontology::OntologyMethods::OBO_TYPEDEFS.include?(r.interaction)}
    @xref_keywords = @proj.keywords.that_are_xrefs
    
    # a little check
    if @proj.ontology_namespace.blank?
      flash[:notice] = "Project not fully configured to dump OBO files.  Check that ontology namespace is set."
      redirect_to :controller => :proj, :id => @proj.id, :action => :edit and return 
    end

    @terms = @proj.ontology_classes.with_xref_namespace(@proj.ontology_namespace).with_obo_label.ordered_by_xref # sort{|a,b| a.obo_xref <=> b.obo_xref}
    render :file => 'ontology/obo/show_OBO_file', :use_full_path => true, :layout => false, :content_type => 'text/plain'
  end

  def show_external_OBO_file
    if request.post?
      if params[:file].blank?
        flash[:notice] = 'Choose an OBO file first.'
        redirect_to :action => :show_external_OBO_file and return
      end
      
      params[:file].rewind
      @obo_file = parse_obo_file(params[:file].read)
      if !params[:keyword].blank? && !params[:keyword][:id].blank?
        @keyword = Keyword.find(params[:keyword][:id]) 
        @labels = @proj.labels.tagged_with_keyword(@keyword)
      else
        @labels = @proj.labels
      end
      
      @obo_minus_labels = (@obo_file.term_strings - @labels.collect{|l| l.name})
      @labels_minus_obo = (@labels.collect{|l| l.name} - @obo_file.term_strings)
    end
    
    render :file => 'ontology/obo/show_external_OBO_file', :layout => true
  end

  def export_class_depictions
    rdf = Ontology::Mx2owl.class_depictions(@proj)
    render(:text => rdf, :type => 'application/rdf+xml')
  end

  def _ref_context_for_label
    @refs = @proj.refs.ordered_by_cached_display_name.with_ocr_text_containing(params[:label_name])
    render :update do |page|
      page.replace_html "result_for_label_" + params[:label_name].gsub(/\s/,"_"), :partial => 'ref/context_for_label', :locals => {:refs => @refs, :label_name => params[:label_name]} 
    end and return
  end

  def stats
  end

  def visualize_dot
    @data = Ontology::Visualize::Graphviz.dot(:proj_id => @proj.id)
    render :action => 'visualize/visualize_dot'
  end

  def analyze
   
    respond_to do |format|
     format.html { # not hit yet
        render :action => 'ontology/analyzer/index'         
     }
     format.js {
    
    @txt = params["text_to_analyze"]
    text = params["text_to_analyze"]

    if @txt.strip.length == 0
      flash[:notice] = 'Provide some text.'
      redirect_to :action => :analyze and return
    end

    @adjacent_words_to_fuse = params[:adjacent_words_to_fuse].to_i 
    @exclude_common_words  = (params[:exclude_common_words] || false)
    @match_type = (params[:match_type] ? :predicted : :exact)

    @l = Linker.new(
                    :link_url_base => self.request.host,
                    :proj_id => @proj.id,
                    :adjacent_words_to_fuse => @adjacent_words_to_fuse,
                    :incoming_text => text,
                    :exclude_common_words => @exclude_common_words,
                    :match_type => @match_type)
 
       render :update do |page|
       page.replace_html :result, :partial => 'ontology/analyzer/result' 
       end and return
     }
    end
  end

  def download_analyzer_result
    @l = Linker.new(
                :link_url_base => self.request.host,
                :proj_id => @proj.id,
                :adjacent_words_to_fuse => params[:adjacent_words_to_fuse].to_i,
                :incoming_text => params[:text],
                :exclude_common_words => params[:exclude_common_words],
                :match_type => params[:match_type].to_sym
               )

    f = @l.tab_file
    send_data(f, :filename => 'material_and_methods.tab', :type => "application/rtf", :disposition => "attachment")
  end

end
