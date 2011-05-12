class GeogTypeController < ApplicationController
 verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  
  def index
    list
    render :action => 'list'
  end

  def list
    @geog_type_pages, @geog_types = paginate :geog_type, :per_page => 10
  end

  def show
    @geog_type = GeogType.find(params[:id])
  end

  def new
    @geog_type = GeogType.new
  end

  def create
    @geog_type = GeogType.new(params[:geog_type])
    if @geog_type.save
      flash[:notice] = 'GeogType was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @geog_type = GeogType.find(params[:id])
  end

  def update
    @geog_type = GeogType.find(params[:id])
    if @geog_type.update_attributes(params[:geog_type])
      flash[:notice] = 'GeogType was successfully updated.'
      redirect_to :action => 'show', :id => @geog_type
    else
      render :action => 'edit'
    end
  end

  def destroy
    GeogType.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
