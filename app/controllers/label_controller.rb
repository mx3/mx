require 'ontology/ontology_methods'

class LabelController < ApplicationController

  verify :method => :post, :only => [ :destroy, :create ], # :update
    :redirect_to => { :action => :list }

  before_filter :_show_params, :only => [:show, :show_tags]

  def index
    list
    render :action => 'list'
  end

  def list
    list_params
    if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def new
    @label = Label.new
    @label.plural_of_label_id = params[:id] if !params[:id].blank?
  end

  def create
    @label = Label.new(params[:label])
    if @label.save
      flash[:notice] = "Label was successfully created."
      redirect_to :action => :show, :id => @label
    else
      render :action => :new
    end
  end

  def destroy
    @label = Label.find(params[:id])
    if @label.destroy
      flash[:notice] = "Label destroyed."
      redirect_to :action => :list
    else
      flash[:notice] = "Can not destroy label, it is likely used with an ontology class that has a xref."
      redirect_to :action => :show, :id => @label
    end
  end

  def show
    @show = ['default']
    @no_right_col = true
    @ocswl = @proj.ontology_classes.with_definition_containing(@label.name)
    render :action => 'show'
  end

  def show_tags
    @tags = @label.tags.group_by{|o| o.addressable_type}
    @no_right_col = true
    render :action => 'show'
  end

  def edit
    @label = Label.find(params[:id], :include => [:ontology_classes])
  end

  def update
    @label = Label.find(params[:id])
    if @label.update_attributes(params[:label])
      flash[:notice] = "Updated."
      redirect_to :action => :show, :id => @label
    else
      flash[:notice] = "Failed to update, did the proposed change result in a duplicate label?"
      redirect_to :action => :edit, :id => @label
    end
  end

  def list_by_keyword
    render :action => :list_by_keyword and return if params[:kw].blank? || params[:kw][:id].blank? 
    respond_to do |format|
      format.html { 
      }
      format.js { # hit on request 
        @keyword = Keyword.find(params[:kw][:id])
        render :update do |page|
          page.replace_html :results, :partial => 'list_edit_ontology_classes', :locals => {:keyword => @keyword, :labels => @proj.labels.tagged_with_keyword(@keyword)}
        end and return
      }
    end      
  end

  def list_by_scope
    if params[:arg]
      @labels = @proj.labels.send(params[:scope],params[:arg]).ordered_by_name
    else
      @labels = @proj.labels.send(params[:scope]).ordered_by_name
    end 
    @title = "Labels #{params[:scope].humanize.downcase} (#{@labels.size})" 
    render :file => 'label/generic_list',:use_full_path => true, :layout => true
  end

  def list_without_definitions
    @labels = @proj.labels.singular.without_ontology_classes.ordered_by_name
    @title = "Labels without associated ontology classes (#{@labels.size})"
    render :file => 'label/generic_list',:use_full_path => true, :layout => true
  end

  def list_homonyms
    @labels = Ontology::OntologyMethods.homonyms(:proj_id => @proj.id)
    @title = "Homonymous labels (#{@labels.size})"
    render :file => 'label/generic_list_with_ontology_classes', :use_full_path => true, :layout => true
  end

  def list_synonyms
    @labels = @proj.labels.that_are_synonyms.ordered_by_name
    @title = "Synonymous labels (#{@labels.size})"
   # render :file => 'label/generic_list_with_ontology_classes', :use_full_path => true, :layout => true
  end

  def list_by_active_on
    @labels = @proj.labels.ordered_by_active_on.limit(50) 
    @title = "Recently active labels (#{@labels.map(&:name).size})"
    render :file => 'label/generic_list_with_ontology_classes', :use_full_path => true, :layout => true
  end

  def list_alpha
    if params[:letter] == nil
      @labels = []
    else
      @labels = @proj.labels.with_first_letter(params[:letter]).singular.ordered_by_name
    end
  end

  def list_without_plural
    @labels = @proj.labels.singular.without_plural_forms.ordered_by_name[0..20]
  end

  def list_lbls_in_defs_wo_ontology_classes
    @result_hash = Label.without_ontology_classes_but_used_in_ontology_class_definitions(:proj_id => @proj)
  end

  def list_simple_with_tags
        render :action => :list_simple_with_tags and return if params[:kw].blank? || params[:kw][:id].blank? 
    respond_to do |format|
      format.html {
      }
      format.js {
        render :update do |page|
          page.replace_html :results, :partial => 'simple_tag', :locals => {:keyword => Keyword.find(params[:kw][:id]), :labels => @proj.labels.ordered_by_name(:include => [:tags])}
        end and return
      }
     end   
  end

  def auto_complete_for_label
    @labels = Label.auto_complete_search_result(params.merge!(:proj_id => @proj.id))
    render :inline => "<%= auto_complete_result_with_ids(@labels,
          'format_obj_for_auto_complete', @tag_id_str) %>"
  end

  protected
  
  def _show_params
    id = params[:label][:id] if params[:label]
    id ||= params[:id]
    @label = Label.find(id)
  end

  def list_params
    @label_pages, @labels = paginate :label, :per_page => 25, :conditions => "(labels.proj_id = #{@proj.id})", :include => [:creator, :updator, :ontology_classes, :plural_form]
  end

end
