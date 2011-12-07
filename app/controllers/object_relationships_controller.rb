class ObjectRelationshipsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list
    @object_relationships = @proj.object_relationships
  end

  def show
    @object_relationship = ObjectRelationship.find(params[:id])
  end

  def new
    @object_relationship = ObjectRelationship.new
  end

  def create  
    @object_relationship = ObjectRelationship.new(params[:object_relationship]) 
    if @object_relationship.save
      flash[:notice] = 'ObjectRelationship was successfully created.'
      redirect_to :action => :show, :id => @object_relationship
    else
      render :action => 'new'
    end
  end

  def edit
    @object_relationship = ObjectRelationship.find(params[:id])
  end

  def update
    @object_relationship = ObjectRelationship.find(params[:id])
    if @object_relationship.update_attributes(params[:object_relationship])
      flash[:notice] = 'ObjectRelationship was successfully updated.'
      redirect_to :action => 'show', :id => @object_relationship
    else
      render :action => 'edit'
    end
  end

  def destroy
    ObjectRelationship.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def up
    ObjectRelationship.find(params[:id]).move_higher
    redirect_to :action => 'list'
  end
  
  def down
    ObjectRelationship.find(params[:id]).move_lower
    redirect_to :action => 'list'
  end
  
end
