class GeogsController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list 
    @geogs = Geog.page(params[:page]).per(20).order('name')
  end

  def show 
    id = params['geog']['id'] if params['geog'] # for autocomplete/ajax picker use
    id ||= params['geog_to_find']['id'] if params['geog_to_find'] # for ajax picker use 
    id ||= params['id']
    
    if @geog = Geog.find(:first, :conditions => ["id = ?", id])
    else 
      flash[:notice] =  "hmm... can't find that geographic name!!!"  
      redirect_to :action => 'list'
    end
  end

  def new
    @geog = Geog.new
  end

  def create
    @geog = Geog.new(params[:geog])
  
    if @geog.save
      flash[:notice] = 'Geog was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @geog = Geog.find(params[:id])
  end

  def update
    @geog = Geog.find(params[:id])
    if @geog.update_attributes(params[:geog])
      flash[:notice] = 'Geog was successfully updated.'
      redirect_to :action => 'show', :id => @geog
    else
      render :action => 'edit'
    end
  end

  def destroy
    begin
      Geog.find(params[:id]).destroy
    rescue
      flash['notice'] = "This geography is being used elsewhere and can't be deleted until it is removed from use." 
    end
    redirect_to :action => 'list'
  end
  
  def auto_complete_for_geogs
    value = params[:term]
    if params[:geog_types] != 'all'
      type_cond = params[:geog_types].split(",").collect{|t| "geogs.geog_type_id = #{t}"}.join(" OR ")
      conditions = ["(#{type_cond}) AND geogs.name LIKE ?", "#{value}%"]
    else
      conditions = ["geogs.name LIKE ?", "#{value}%"]
    end
    @geogs = Geog.find(:all, :conditions => conditions, :limit => 35, :include => :geog_type, :order => 'geogs.name')

    data = @geogs.collect do |g|
      {:id=> g.id,
       :label=> g.display_name,
       :response_values=> {
        'geog[id]' => g.id
       },
       :label_html => render_to_string(:partial => 'shared/autocomplete/geog.html', :object => g)
      }
    end
    render :json => data 
  end
  
end
