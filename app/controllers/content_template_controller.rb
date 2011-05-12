class ContentTemplateController < ApplicationController
  # !! 'template' is reserved, so don't try @template

  verify :method => :post, :only => [ :destroy, :create, :update ],
  :redirect_to => { :action => :list }

  def index
    list
    render :action => 'list'
  end

  def list
    @con_templates = @proj.content_templates
  end

  def show
    id = params[:content_template][:id] if params[:content_template]
    id ||= params[:id]
    @con_template = ContentTemplate.find(id, :include => [:content_types] )
    @content_types = @con_template.content_templates_content_types(:include => :content_type)
    @available_content_types = @con_template.available_text_content_types
    @available_built_in_content_types = @con_template.available_mx_content_types
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
      redirect_to :action => 'list'
    else
      flash[:notice] = 'Problem creating content template.'
      render :action => :edit, :id => @content_template.id
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

  def show_page
    @otu = Otu.find(params[:otu_id])
    @content_template = ContentTemplate.find(params[:ct_id])
    @back = true
    # the basic page is also a partial we use elsewhere
    render :template => "/content_template/_page", :locals => {:content => @content_template.content_by_otu(@otu, false)}


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
    @tag_id_str = params[:tag_id]

    if @tag_id_str == nil
      redirect_to(:action => 'index', :controller => 'content_template') and return
    else

      value = params[@tag_id_str.to_sym].split.join('%') 
      @content_templates = ContentTemplate.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{value}%", value.gsub(/\%/, ""), @proj.id], :order => "name")
    end

    render :inline => "<%= auto_complete_result_with_ids(@content_templates,
    'format_obj_for_auto_complete', @tag_id_str) %>"
  end


end
