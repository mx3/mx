class ContentTypesController < ApplicationController
     
  def index
    list
    render :action => 'list'
  end
  
  def list_params
    @content_type_pages, @content_types = paginate :content_type, :per_page => 20, :order => 'doc_name, name', :conditions => ['proj_id = (?)', @proj.id]
  end

  def list
    list_params
     if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def list_by_type
    @ct = ContentType.find(params[:id], :include => [:contents, :otus])  
  end

  def show
    id = params[:content_type][:id] if params[:content_type] # for autocomplete/ajax picker use (must come first!)
    id ||= params[:id]
    @content_type = ContentType.find(id)
    @show = ['default'] # array of partials to render 
  end

  def new
    @content_type = ContentType.new
  end

  def create
    @content_type = ContentType.new(params[:content_type])
    if @content_type.save
     flash[:notice] = 'Content type was successfully created.'
      redirect_to :action => :show, :id => @content_type
    else
      render :action => 'new'
    end
  end

  def edit
    @content_type = ContentType.find(params[:id])
  end

  def update
    @content_type = ContentType.find(params[:id])
    if @content_type.update_attributes(params[:content_type])
      flash[:notice] = 'ContentType was successfully updated.'
      redirect_to :action => :show, :id => @content_type.id
    else
      render :action => :edit
    end
  end

  def destroy
    ContentType.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def auto_complete_for_content_type
    value = params[:term]
    conditions = ["name LIKE ? AND proj_id = ?", "%#{value}%", @proj.id]
    @content_types = ContentType.find(:all, :conditions => conditions, :order => 'name')
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @content_types, :method => params[:method])
  end
end
