class NewsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list
    @news = News.by_proj(@proj)
     .page(params[:page])
     .per(20)
  end

  def list_admin
    @news_pages, @news = paginate :news, :per_page => 60,  :conditions => 'proj_id is null'  
    render :action => 'list'
  end

  def show
    @news = News.find(params[:id])
  end

  def new
    @news = News.new
  end

  def create
    @news = News.new(params[:news])

    # since we can't use has_standard_fields need to do this!?!
     @news.created_on = Time.now
     @news.updated_on = Time.now
     @news.creator_id = $person_id
     @news.updator_id = $person_id
    
    @news.proj_id = nil if @proj.blank?
    
    if @news.save
      flash[:notice] = "News was successfully created "
    
      if @proj.blank?
          redirect_to :action => 'list_admin'
      #  redirect_to :action => 'list'        
      else
        redirect_to :action => 'list'
      end
    
    else
      render :action => 'new'
    end
  end

  def edit
    @news = News.find(params[:id])
  end

  def update
    @news = News.find(params[:id])
    if @news.update_attributes(params[:news])
      flash[:notice] = 'News was successfully updated.'
      redirect_to :action => 'show', :id => @news
    else
      render :action => 'edit'
    end
  end

  def destroy
    News.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
