class Public::OntologyClassesController < Public::BaseController

  def index 
    redirect_to :action => :index, :controller => '/public/ontology'
  end

  def show
    @ontology_class = OntologyClass.find(params[:id])  
    @definition = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :is_public => true, :incoming_text => @ontology_class.definition, :adjacent_words_to_fuse => 5).linked_text
  end

  def show_expanded
    @ontology_class = OntologyClass.find(params[:id])  
    @definition = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :is_public => true, :incoming_text => @ontology_class.definition, :adjacent_words_to_fuse => 5).linked_text
    @figures = @ontology_class.figures.with_figure_markers  
    
    @is_a = @proj.object_relationships.by_interaction('is_a').first 
    @part_of = @proj.object_relationships.by_interaction('part_of').first 
    @attaches_to = @proj.object_relationships.by_interaction('attaches_to').first 
  end

  def random
    ids = @proj.ontology_classes.with_populated_xref.that_are_not_obsolete
    redirect_to :action => :show, :id => ids[rand(ids.size)] and return
  end

  def auto_complete_for_ontology_class
    @ontology_classes = OntologyClass.auto_complete_search_result(params.merge!(:proj_id => @proj.id)) # TODO: mx3 - needs major refactoring
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @ontology_classes, :method => params[:method])
  end  

end


