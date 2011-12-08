class ImageViewsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list
    @image_views = ImageView.all 
  end

  def show
    @image_view = ImageView.find(params[:id])
  end

  def new
    @image_view = ImageView.new
  end

  def create
    @image_view = ImageView.new(params[:image_view])
    if @image_view.save
      flash[:notice] = 'ImageView was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @image_view = ImageView.find(params[:id])
  end

  def update
    @image_view = ImageView.find(params[:id])
    if @image_view.update_attributes(params[:image_view])
      flash[:notice] = 'ImageView was successfully updated.'
      redirect_to :action => 'show', :id => @image_view
    else
      render :action => 'edit'
    end
  end

  def destroy
    ImageView.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
