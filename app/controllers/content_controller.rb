class ContentController < ApplicationController

  verify :method => :post, :only => [ :update ],
    :redirect_to => { :action => :list }

  # Content isn't directly dealt with, rather this is controller for grouping various functions

  def index
    list
    render :action => :list
  end

  def list  
    @otus = @proj.otus.with_content
    @display_data = ByTnDisplay.new(nil, @otus)
  end

  def show
    # finds the OTU that the content belongs to, and jumps there
    id = params[:content][:id] if params[:content]
    id ||= params[:id]    
    @con = Content.find(id)
    redirect_to :action => :show_all_content, :controller => :otu, :id => @con.otu_id and return
  end

  def show_figures
    id = params[:content][:id] if params[:content]
    id ||= params[:id]    
    redirect_to :action => :show, :id => id  and return
  end

  def edit
    @content = Content.find(params[:id], :include => [:otu])
    @content_template = ContentTemplate.find(params[:content_template_id])
  end

  def update
    @content = Content.find(params[:id], :include => [:otu])
    @content_template = ContentTemplate.find(params[:content_template_id])
    if @content.update_attributes!(params[:content])
      flash[:notice] = 'Updated.'
    end
    render :action => :edit 
  end 

  def auto_complete_for_content
    value = params[:term]
    if value.nil?
      redirect_to(:action => 'index', :controller => 'content') and return
    else
      # val = value.split.join('%') 
      lim = case value.length
            when 1..2 then  10
            when 3..4 then  25
            else lim = false # no limits
            end 

      @contents = Content.find(:all, :conditions => ["(text LIKE ? OR id = ?) AND proj_id = ? AND pub_content_id IS NULL", "%#{value}%", value.gsub(/\%/, ""), @proj.id], :order => "id", :limit => lim).uniq
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @contents, :method => params[:method])
  end

  def publish_all
    if @otu = Otu.find(params[:otu_id], :conditions => "proj_id = #{@proj.id}")
      @otu.publish_all_content
      flash[:notice] = "Published!"
    else
      flash[:notice] = "Can't find that OTU"
    end
    redirect_to :action => :list        
  end

  def sync
  end

end
