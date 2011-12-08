class LotGroupsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list
    @lot_groups = LotGroup.by_proj(@proj)
    .page(params[:page])
    .per(20)
  end

  def show 
    id = params[:id]
    id ||= params[:lot_group][:id]
    @lot_group = LotGroup.find(id)
    @show = ['default'] 
  end

  def show_members
    @lot_group = LotGroup.find(params[:id])
    @lots = @lot_group.lots
    @no_right_col = true
    render :action => 'show'
  end
  
  def new
    @lot_group = LotGroup.new
  end

  def create
    @lot_group = LotGroup.new(params[:lot_group])
    if @lot_group.save
      flash[:notice] = 'LotGroup was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @lot_group = LotGroup.find(params[:id])
  end

  def update
    @lot_group = LotGroup.find(params[:id])
    if @lot_group.update_attributes(params[:lot_group])
      flash[:notice] = 'LotGroup was successfully updated.'
      redirect_to :action => 'show', :id => @lot_group
    else
      render :action => 'edit'
    end
  end

  def destroy
    LotGroup.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def add_lot
    @lot_group = LotGroup.find(params[:lot_group][:id])
    if params[:lot][:id]
      begin

        @lot_group.lots << Lot.find(params[:lot][:id])
      rescue
        flash[:notice] = 'Failed to add lot, it is likely already present.'
        redirect_to :action => 'show_members', :id => @lot_group.id  and return  
      end
        
      flash[:notice] = 'Added a lot.'
    end    
    redirect_to :action => 'show_members', :id => @lot_group.id    
  end

  def remove_lot
    @lot_group = LotGroup.find(params[:lot_group_id])
    @lot_group.lots.delete(Lot.find(params[:id]))
    redirect_to :action => 'show_members', :id => @lot_group.id    
  end
  
  def grand_summary
    @lot_groups = @proj.lot_groups(:order => 'name ASC') 
  end

  def auto_complete_for_lot_group
    value = params[:term]
    if value.nil? 
      redirect_to :previous 
    else
      val = params[@tag_id_str.to_sym].split.join('%') 
      lim = case value.length
            when 1..2 then  10
            when 3..4 then  25
            else lim = false 
            end 
      @lot_groups = LotGroup.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{val}%", val.gsub(/\%/, ""), @proj.id], :order => "name", :limit => lim )
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @lot_groups, :method => params[:method])
  end
  
  
end
