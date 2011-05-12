class DistributionController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }
    
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @distribution_pages, @distributions = paginate :distributions, :per_page => 30,
    :order_by => 'otu_id', :conditions => ['proj_id = (?)', @proj.id]
  end

  def show
    @distribution = Distribution.find(params[:id])
  end

  def new
    @distribution = Distribution.new
  end

  def create
    @distribution = Distribution.new(params[:distribution])
    if @distribution.save
      flash[:notice] = 'Distribution was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @distribution = Distribution.find(params[:id])
  end

  def update
    @distribution = Distribution.find(params[:id])
    if @distribution.update_attributes(params[:distribution])
      flash[:notice] = 'Distribution was successfully updated.'
      redirect_to :action => 'show', :id => @distribution
    else
      render :action => 'edit'
    end
  end

  def destroy
    Distribution.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
