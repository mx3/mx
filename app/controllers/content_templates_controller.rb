class ContentTemplatesController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list
    @content_templates = ContentTemplate.by_proj(@proj).page(params[:page]).per(20)
  end

  def show
    id = params[:content_template][:id] if params[:content_template]
    id ||= params[:id]
    @con_template = ContentTemplate.find(id, :include => [:content_types] )
    @content_types = @con_template.content_templates_content_types(:include => :content_type)
    @available_content_types = @con_template.available_text_content_types
    @available_built_in_content_types = @con_template.available_mx_content_types
  end

  # TODO: non-standard show_
  def show_page
    @otu = Otu.find(params[:otu_id])
    @content_template = ContentTemplate.find(params[:ct_id])
    @back = true
    # the basic page is also a partial we use elsewhere
    render :template => "/content_templates/_page", :locals => {:content => @content_template.content_by_otu(@otu, false)}
  end

  def sort_content_types
    params[:content_types].each_with_index do |id, index|
      ContentTemplatesContentType.update_all(['position=?', index+1], ['foo_id=?', id]) # foo_id is a holdover from WAAAY back, needs to update
    end
    render :nothing => true
  end

  def new
    @content_template = ContentTemplate.new 
    render :action => :new
  end

  def create  
    @content_template = ContentTemplate.new(params['content_template'])
    if @content_template.save          
      flash[:notice] = 'Content template was successfully created.'
      redirect_to :action => :show, :id => @content_template
    else
      flash[:notice] = 'Problem creating content template.'
      render :action => :new
    end
  end

  def edit
    @content_template = ContentTemplate.find(params[:id])
  end

  def update
    @con_template = ContentTemplate.find(params[:id])
    if @con_template.update_attributes(params[:content_template])
      flash[:notice] = 'ConTemplate was successfully updated.'
      redirect_to :action => :show, :id => @con_template.id
    else
      render :action => :edit
    end
  end

  def destroy
    ContentTemplate.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def add_remove_type
    @con_template = ContentTemplate.find(params[:id])

    if @con_template.add_or_remove_content_type(params)
      if params[:out]
        flash[:notice] = "Removed a content type."
      else
        flash[:notice] = "Added a content type."
      end
    else
      if params[:out]
        flash[:notice] = "Error removing content type."
      else
        flash[:notice] = "Error adding content type."         
      end
    end
    redirect_to :action => 'show', :id => @con_template.id
  end

  def make_default
    ContentTemplate.update_all "is_default = 0", "proj_id = #{@proj.id}"
    ContentTemplate.find(params['id']).update_attribute("is_default", 1) # skips validation
    redirect_to :action => 'list'
  end 

  def auto_complete_for_content_template
    value = params[:term]
    if value.nil?
      redirect_to(:action => 'index', :controller => 'content_templates') and return
    else
      val = value.split.join('%') 
      @content_templates = ContentTemplate.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{val}%", val.gsub(/\%/, ""), @proj.id], :order => "name")
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @content_templates, :method => params[:method])
  end

end
