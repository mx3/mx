class StandardViewGroupsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end
 
  def list
    @standard_view_groups = StandardViewGroup.by_proj(@proj).page(params[:page]).per(20).order('name')
  end

  def show
    id = params[:standard_view_group][:id] if params[:standard_view_group]
    id ||= params[:id]
    
    @standard_view_group = StandardViewGroup.find(id)
    @standard_views_in = @standard_view_group.standard_views
    @standard_views_out = @proj.standard_views - @standard_views_in
  end

  def new
    @standard_view_group = StandardViewGroup.new
  end

  def create
    @standard_view_group = StandardViewGroup.new(params[:standard_view_group])
    if @standard_view_group.save
      flash[:notice] = 'StandardViewGroup was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @standard_view_group = StandardViewGroup.find(params[:id])
  end

  def update
    @standard_view_group = StandardViewGroup.find(params[:id])
    if @standard_view_group.update_attributes(params[:standard_view_group])
      flash[:notice] = 'StandardViewGroup was successfully updated.'
      redirect_to :action => 'show', :id => @standard_view_group
    else
      render :action => 'edit'
    end
  end

  def destroy
    StandardViewGroup.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def add_standard_view
    @standard_view_group = StandardViewGroup.find(params[:id])
    
    if params[:standard_view_id]
      # check for non-duplication ultimately (right now comes from pick-list, so no chance of dupes)
      standard_view = StandardView.find(params[:standard_view_id])
      @standard_view_group.standard_views << standard_view
      @standard_view_group.save!
    end   
    redirect_to :action => 'show', :id => @standard_view_group.id    
  end
  
  def remove_standard_view
    @standard_view_group = StandardViewGroup.find(params[:id])
    @standard_view_group.standard_views.delete(StandardView.find(params[:standard_view_id]))  
    redirect_to :action => 'show', :id => @standard_view_group.id    
  end
 

  def auto_complete_for_standard_view_group
    value = params[:term]
    if value.nil? 
      redirect_to(:action => 'index', :controller => 'standard_views') and return
    else
      val = value.split.join('%') # hmm... perhaps should make this order-independent
      lim = case value.length
            when 1..2 then  10
            when 3..4 then  25
            else lim = false # no limits
            end 
      @standard_view_groups = StandardViewGroup.find(:all, :conditions => ["(name LIKE ? or id = ?) AND proj_id=?", "%#{val}%", val.gsub(/\%/, ""), @proj.id], :order => "name", :limit => lim)
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @standard_view_groups, :method => params[:method])
  end

  
  
end
