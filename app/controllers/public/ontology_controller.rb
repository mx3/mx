require 'ontology/ontology_methods'

class Public::OntologyController < Public::BaseController

  verify :method => :post, :only => [ :search ],
    :redirect_to => { :action => :index }

  def index 
  end

  def search
    not_found = "Result not found, did you select an item from the picklist?"
    if (params[:search].blank? || params[:search][:ontology_class_id].blank?) 
      flash[:notice] = not_found 
      render :action => :index
    else 
      if @ontology_class = OntologyClass.find(params[:search][:ontology_class_id])
        redirect_to :action => :show, :controller => :ontology_classes, :id => @ontology_class.id
      else
        flash[:notice] = not_found 
        redirect_to :action => :index 
      end
    end
  end

  def proof
    respond_to do |format|
      format.html { 
      }
      format.js {
        render :update do |page|
        @l = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :is_public => true, :public_server_name => @proj.public_server_name, :incoming_text =>  truncate(params[:txt].to_s, :length => 10000).to_s, :adjacent_words_to_fuse => 5)
        page.replace_html :proofed_text, :partial =>  'proofed'
        end and return
      }
    end      
  end

  def refs
  end

 #def show_contributors

 #  redirect_to :action => :show_term and return
 #  # TODO: move this to models
 #  @pids = (Part.find_by_sql(["Select distinct creator_id i from parts where proj_id = ?;", @proj.id]) + 
 #           Part.find_by_sql(["Select distinct updator_id i from parts where proj_id = ?;", @proj.id]) +
 #           Ontology.find_by_sql(["Select distinct creator_id i from ontologies where proj_id = ?;", @proj.id]) +
 #           Ontology.find_by_sql(["Select distinct updator_id i from ontologies where proj_id = ?;", @proj.id]))

 #  @people = Person.find(@pids.collect{|o| o.i}, :order => 'last_name')

 #  # could do this in some crosstab I'm sure but...
 #  @result = HashFactory.call
 #  for p in @people
 #    @result[p.full_name][:part][:creator] = Part.find(:all, :conditions => "creator_id = #{p.id} and proj_id = #{@proj.id}").size
 #    @result[p.full_name][:part][:updator] = Part.find(:all, :conditions => "updator_id = #{p.id} and proj_id = #{@proj.id}").size
 #    @result[p.full_name][:ont][:creator] = Ontology.find(:all, :conditions => "creator_id = #{p.id} and proj_id = #{@proj.id}").size
 #    @result[p.full_name][:ont][:updator] = Ontology.find(:all, :conditions => "updator_id = #{p.id} and proj_id = #{@proj.id}").size
 #    @result[p.full_name][:fig][:creator] = Figure.find(:all, :conditions => "creator_id = #{p.id} and proj_id = #{@proj.id}").size
 #    @result[p.full_name][:fig][:updator] = Figure.find(:all, :conditions => "updator_id = #{p.id} and proj_id = #{@proj.id}").size
 #    @result[p.full_name][:tag][:creator] = Tag.find(:all, :conditions => "creator_id = #{p.id} and proj_id = #{@proj.id}").size
 #    @result[p.full_name][:tag][:updator] = Tag.find(:all, :conditions => "updator_id = #{p.id} and proj_id = #{@proj.id}").size
 #  end
 #end

  def tree
    @treetop = @proj.default_ontology_class
    @proj.ontology_classes.first if !@treetop
    redirect_to :action => :new, :controller => :ontology_classes and return if !@treetop
    @colored_object_relationships = @proj.object_relationships.with_color_set
    @all_object_relationships = @proj.object_relationships 
    render :action => 'tree/index'
  end

  def _tree_set_root
    render :layout => false, :nothing => true and return if !params[:ontology_class]
    @treetop = OntologyClass.find(params[:ontology_class][:id])
    render :layout => false, :partial => '/public/ontology/tree/tree_index', :locals => { :relationship_type => ((params[:object_relationship] && params[:object_relationship][:id] && !params[:object_relationship][:id].blank?) ? params[:object_relationship][:id]  : 'all' ), :max_depth => (params[:max_depth].to_i || 2)}
  end 

  # open and close a node
  def _tree_navigate_through_child
   if params[:parent_relationship] != "root" 
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
   else
    render :update do |page|
       page.replace_html "ontology_tree_info_target", :text => content_tag(:div, "You can't close the root node.", :style => 'text-align:center;font-weight: bolder;color:red; font-size:bolder;padding: 1em; border:1px solid silver; margin: 2em;')
    end and return
   end    
  end

  def _tree_populate_target
    @ontology_class = OntologyClass.find_by_id(params[:id])
    @definition = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :is_public => true, :incoming_text => @ontology_class.definition, :adjacent_words_to_fuse => 5).linked_text
    render :update do |page|
      txt = render(:partial => '/public/ontology_class/oc_def', :locals => {:oc => @ontology_class} ) 
      page.replace_html "ontology_tree_info_target", txt + content_tag(:div, link_to('- more detail -', :action => :show_expanded, :controller => :ontology_classes, :id => @ontology_class.id), :style => 'text-align: center;', :target => '_blank')
    end and return       
  end

  def pulse
    @active_labels = @proj.labels.ordered_by_active_on.limit('40')
  end

  # thanks http://paulsturgess.co.uk/articles/show/13-creating-an-rss-feed-in-ruby-on-rails
  def pulse_rss
    @active_labels = @proj.labels.ordered_by_active_on.limit('40')
     render :layout => false
     response.headers["Content-Type"] = "application/xml; charset=utf-8"
   end

  def parts
    if request.xml_http_request?
      if (params[:search].blank? || params[:search][:id].blank?) 
        flash[:notice] = "Not found, choose a option from the list."
        redirect_to :action => :parts and return
      end

      if @part_of = @proj.object_relationships.by_interaction('part_of').first
        @ontology_classes = OntologyClass.find(params[:search][:id]).related_ontology_relationships(:relationship_type => [@part_of.id]).uniq.sort{|a, b| a.ontology_class1.label_name(:type => :preferred) <=> b.ontology_class1.label_name(:type => :preferred)}
        render :update do |page|
          page.replace_html :results, :partial =>  '/public/ontology_class/simple_table'
        end and return

      else
        render :update do |page|
          page.replace_html :results, :text => "Site needs administration configuration and a part_of object relationship."
        end and return
      end 
    end
  end

end
