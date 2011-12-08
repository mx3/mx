class ClavesController < ApplicationController
  # Claves are bifurcating/dichotomous keys
  
  def index
    list
    render :action => 'list'
  end

  def list
    @claves = Clave.by_proj(@proj).page(params[:page]).per(20).order('couplet_text').where('parent_id is null')
  end

  def show
    id = params[:clave][:id] if params[:clave]
    id ||= params[:id]

    @clave = Clave.find(id)
    @clave = @clave.parent if params[:clave] and params[:clave][:id] # we hit this when we search, and in fact want to display the found clave, not its children
    
    children = @clave.children(:order => :position)
    if children.size == 2
      @left = children[0]
      @right = children[1]
    end
    
    @left_text = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :incoming_text => @left.couplet_text, :adjacent_words_to_fuse => 5).linked_text(:is_public => false)
    @right_text = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :incoming_text => @right.couplet_text, :adjacent_words_to_fuse => 5).linked_text(:is_public => false)

    @left_future = @left.future
    @right_future = @right.future
    
    @parents = @clave.ancestors.reverse!
  end

  def show_all
    @clave = Clave.find(params[:id])
    @key = @clave.all_children
  end

  def show_all_print
    @clave = Clave.find(params[:id])
    @key = @clave.all_children_standard_key
    # render :layout => false
  end
  
  def new_couplet
    # assumes the parent node is @clave
    @left = @clave.children.create(:couplet_text => '') #, :parent_id => nil) # and give it two nodes
    @right = @clave.children.create(:couplet_text => '') #, :parent_id => nil)
    @left_future = @left.future
    @right_future =  @right.future
  end

  def new
    @clave = Clave.new # make a new head node
  end

  def create
    @clave = Clave.new(params[:clave]) 
    if @clave.save
      new_couplet # we make two blank couplets so we can show the key
      flash[:notice] = 'Key was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @clave = Clave.find(params[:id])
    children = @clave.children(:order => :position)
    if children.size == 2
      @left = children[0]
      @right = children[1] 
      @left_future = @left.future
      @right_future = @right.future
    else
      new_couplet
    end
    @parents = @clave.ancestors.reverse!
  end

  def update
    @clave = Clave.find(params[:clave][:id])
    @left = Clave.find(params[:left][:id])
    @right = Clave.find(params[:right][:id])
    begin
      @left.update_attributes(params[:left])
      @right.update_attributes(params[:right])
      @clave.update_attributes(params[:clave]) 
      flash[:notice] = 'Successfully updated!'
    rescue
      flash[:notice] = 'Something went wrong in the save!'
    end
    redirect_to :action => 'edit', :id => @clave
  end

  def destroy_couplet   # logic should be moved to model
    @clave = Clave.find(params[:id])
    children = @clave.children(:order => :position)
    if (children[0].children.size == 0) and (children[1].children.size == 0) and not(@clave.parent_id == nil)
      children[0].destroy
      children[1].destroy
      flash[:notice] = 'Deleted couplet and moved back up.'
    end
    redirect_to :action => :edit, :id => @clave.parent_id
  end

  def delete_couplet # NOT the same as destroy_couplet, this can be if one side has no children but the other does
    @clave = Clave.find(params[:id])
    if @clave.destroy_couplet
      flash[:notice] = 'Destroyed couplet'
    else
      flash[:notice] = 'Failed to destroy couplet'
    end
    redirect_to :action => :edit, :id => @clave
  end

  def destroy
    if @clave = Clave.find(params[:id]) 
    children = @clave.children(:order => :position)
      if ((children[0].children.size == 0) and (children[1].children.size == 0))  
        @clave.destroy # note we allow the AR to do this 
        flash[:notice] = "Deleted."
      else
        flash[:notice] = "Something went wrong."
      end
    end
      redirect_to :action => 'list'    
  end

  def duplicate
    @clave = Clave.find(params[:id])
    @clave.dupe
    redirect_to :action => :list    
  end
  
 def insert_couplet
   @clave = Clave.find(params[:id]) or raise 'problem with insert_couplet'
   @clave.insert_couplet
   
   flash[:notice] = 'Inserted a couplet.'
   redirect_to :action => 'edit', :id => @clave.parent_id 
 end

 # the following two functions update the head node (Claves with no parent_id)
 def edit_meta
   @clave = Clave.find(params[:id])
   render :action => 'edit_meta'
 end

  def update_meta
    @clave = Clave.find(params[:clave][:id])
    if @clave.update_attributes(params[:clave])
      flash[:notice] = "Updated the key"
      redirect_to :action => 'list'
    else
      render :action => 'edit_meta'
    end
  end
    
  def auto_complete_for_clave
    value = params[:term]
    val = value.split.join('%')
    lim = case value.length
          when 1..2 then  10
          when 3..4 then  25
          else lim = false 
          end 
    @claves = Clave.find(:all, :conditions => ["(couplet_text LIKE ? OR id = ?) AND proj_id=?", "%#{val}%", val.gsub(/\%/, ""), @proj.id], :order => "id", :limit => lim )
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @claves, :method => params[:method])
  end
 
end
