class Public::NewsController < Public::BaseController

  def index
    redirect_to :action => :list
  end
 
  def list
    @news = @proj.all_public_news
 #   render :controller => '/public/news'
  end

end



