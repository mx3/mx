class RepositoriesController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list
    @repository_pages, @repositories = paginate :repository, :per_page => 30, :order_by => "coden, name"
     if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def show
    id = params[:id]
    id ||= params[:repository][:id] if params[:repository] # for autocomplete/ajax picker use
    
    if @repository = Repository.find(:first, :conditions => ["id = ?", id])
      return @repository
    else
      flash[:notice] = "Couldn't find a repository with that id."
      redirect_to :action => 'list'
    end
    
  end

  def new
    @repository = Repository.new
  end

  def create
    @repository = Repository.new(params[:repository])
    begin
      Repository.transaction do
        @repository.save!

        if @identifier = Identifier.create_new(params[:identifier].merge(:object => @repository))
          @identifier.save!
        end
      end

    rescue  Exception => e 
      flash[:notice] = e.message 
      render :action => :new and return
    end

   flash[:notice] = 'Repository was successfully created.'
   redirect_to :action => :show, :id => @repository
  end

  def edit
    @repository = Repository.find(params[:id])
  end

  def update
    @repository = Repository.find(params[:id])
    begin
      Repository.transaction do
        @repository.update_attributes(params[:repository])
        if @identifier = Identifier.create_new(params[:identifier].merge(:object => @repository))
          @identifier.save!
        end
      end

    rescue ActiveRecord::RecordInvalid => e 
      flash[:notice] = "Failed to update the record: #{e.message}."
      redirect_to :back and return
    end
    flash[:notice] = 'Repository was successfully updated.'
    redirect_to :action => :show, :id => @repository
  end

  def destroy
    Repository.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def auto_complete_for_repository
    value = params[:term]
    @reps = Repository.find(:all, :conditions => ["name LIKE ? OR coden LIKE ?", "%#{value}%", "%#{value}%"], :limit => 10, :order => 'coden')
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @reps, :method => params[:method])
  end
  
end
