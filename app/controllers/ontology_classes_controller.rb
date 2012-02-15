class OntologyClassesController < ApplicationController
  in_place_edit_for :ontology_class, :definition

  before_filter :_show_params, :only => [:show, :show_tags, :show_figures, :show_history]

  def index
    list
    render :action => 'list'
  end

  def list_by_scope
    if params[:arg]
      @ontology_classes = @proj.ontology_classes.send(params[:scope],params[:arg]).ordered_by_label_name
    else
      @ontology_classes = @proj.ontology_classes.send(params[:scope]).ordered_by_label_name
    end
    @list_title = "Ontology classes #{params[:scope].humanize.downcase}"
    render :action => :list_simple
  end

  def list
    @ontology_classes = OntologyClass.by_proj(@proj)
     .page(params[:page])
     .per(20)
     .includes(:written_by, :obo_label, :creator, :labels, :updator, :taxon_name)
  end

  def list_tip_figures
    @list_title = 'Tip (no is_a children) classes with xref without figure markers'
    if isa = @proj.object_relationships.by_interaction('is_a').andand.first
      @possible_classes = @proj.ontology_classes.with_populated_xref.that_are_not_obsolete.ordered_by_label_name.without_child_relationship(isa).length
      @ontology_classes = @proj.ontology_classes.without_figure_markers.with_populated_xref.that_are_not_obsolete.ordered_by_label_name.without_child_relationship(isa)
    else
      flash[:notice] = "Create a 'is_a' object relationships first, then use it."
      redirect_to :action => :index and return
    end
  end

  def list_by_missmatched_genus
    @ontology_classes =  Ontology::OntologyMethods.ontology_classes_with_definitions_not_matching_is_a(@proj.id)
  end

  def list_simple_with_tags
    render :action => :list_simple_with_tags and return if params[:kw].blank? || params[:kw][:id].blank?
    respond_to do |format|
      format.html {
      }
      format.js {
        render :update do |page|
        page.replace_html :results, :partial => 'simple_tag', :locals => {:keyword => Keyword.find(params[:kw][:id]), :ontology_classes => @proj.ontology_classes.ordered_by_label_name[0..10]}
        end and return
      }
    end
  end

  def list_label_summary
    @ontology_classes = OntologyClass.by_label_including_count(@proj.id)
  end

  def new
    @ontology_class = OntologyClass.new
  end

  def create
    @ontology_class = OntologyClass.new(params[:ontology_class])
    if @ontology_class.save
      flash[:notice] = "Ontology class was successfully created."
      redirect_to :action => :show, :id => @ontology_class
    else
      render :action => :new
    end
  end

  def show
    @show = ['default']
    @no_right_col = true
    render :action => 'show'
  end

  def show_tags
    @tags = @ontology_class.tags.group_by{|o| o.addressable_type}
    @no_right_col = true
    render :action => 'show'
  end

  def show_figures
    @no_right_col = true
    render :action => :show
  end

  def show_history
    @no_right_col = true
    render :action => :show
  end

  def show_next_without
    # filter options :without_sensus, :without_definitions, :without_relationships
    @withouts =  @proj.ontology_classes.send(params[:filter]).excluding_id(params[:id]).ordered_by_id
    if @withouts.size == 0
      flash[:notice] = "There are no ontology classes #{params[:filter]}."
      redirect_to :back
    else
      redirect_to :action => :show, :id => @withouts.first.id
    end
  end

  def edit
    @ontology_class = OntologyClass.find(params[:id])
  end

  def update
    @ontology_class = OntologyClass.find(params[:id])
    if @ontology_class.update_attributes(params[:ontology_class].merge(:updated_by => Person.find($person_id))) # from versioned model
      flash[:notice] = "Updated."
      redirect_to :action => :show, :id => @ontology_class
    else
      @ontology_class.is_obsolete = false # reset on Error
      render :action => :edit
    end
  end

  def destroy
    @ontology_class = OntologyClass.find(params[:id])
    if @ontology_class.destroy
      flash[:notice] = "Class destroyed."
      redirect_to :action => :list
    else
      flash[:notice] = "Can not destroy this record: #{@ontology_class.errors.collect{|e| e.to_sentence}.join("; ")}"
      redirect_to :action => :show, :id => @ontology_class
    end
  end

  def show_visualize_newick
    @no_right_col = true
    id = params[:ontology_class][:id] if params[:ontology_class] ## MUST COME FIRST ##
    id ||= params[:id]
    if id == ""
      flash[:notice] = "Can't find a ontology class with that id, make sure to select the ontology class from the dropdown."
      render :action => :index and return
    end

    if @ontology_class = OntologyClass.find(id)
      _show_params
      @show = ['ontology/visualize/show_visualize_newick']
      render :action => :show
    else
      flash[:notice] = "Can't find a ontology class with that id, make sure to select the ontology class from the dropdown."
      render :action => :index
    end

    @no_right_col = true
  end

  def _render_newick
   root = OntologyClass.find(params[:id])
   @object_relationship = ObjectRelationship.find(params[:object_relationship_id])
   render :update do |page|
      page.replace_html :tree, :partial => 'ontology/visualize/newick_tree', :locals => {
        :root => root,
        :relationship_type => [@object_relationship.id],
        :max_depth => params[:max_depth].to_i,
        :hilight_depth => params[:hilight_depth].to_i,
        :color => params[:color],
        :annotate_value => params[:annotate_value],
        :annotate_index => params[:annotate_index],
        :annotate_branches => params[:annotate_branches],
        :annotate_clades => params[:annotate_clades]}
        # :relationships => @relationships}
    end and return
  end

  def generate_xref
    @ontology_class = OntologyClass.find(params[:id])
    begin
      if OntologyClass.generate_xrefs(:ontology_classes => [@ontology_class], :proj_id => @proj.id, :prefix => @proj.ontology_namespace)
        flash[:notice] = "Xref generated."
      else
        raise
      end
    rescue
      flash[:notice] = "Problem generating xref, does your project have a ontology namespace?  See settings.."
    end
    redirect_to :action => :show, :id => @ontology_class
  end

  def _show_params
    id = params[:ontology_class][:id] if params[:ontology_class]
    id ||= params[:id]
    @ontology_class = OntologyClass.find(id, :include => [:labels, :sensus, :figures, :tags])
  end

  def auto_complete_for_ontology_classes
    value = params[:term]
    @ontology_classes = OntologyClass.auto_complete_search_result(params.merge!(:proj_id => @proj.ontology_id_to_use)) # TODO: need refactoring
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @ontology_classes, :method => params[:method])
  end

  def _populate_consituent_parts
    @cop = OntologyClass.find(params[:id]).logical_relatives(:direction => :children)
    @cop ||= []
    render :update do |page|
      page.replace_html :constituent_parts, :partial => 'logical_ontology_class_list', :locals => {:children_of_part => @cop}
    end and return
  end

  # TODO: dirty updates reverts here?
  def _in_place_definition_update
    t = OntologyClass.find(params[:id])
    t.update_attributes(:definition => params[:value].strip, :updated_by => Person.find($person_id))
    if t.save
      render :text => t.definition
    else
      render :text => '<span style="color: red;">Validation failed, record not updated.</span>'
    end
  end

end
