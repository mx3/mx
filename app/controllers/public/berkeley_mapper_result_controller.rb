class Public::BerkeleyMapperResultController < Public::BaseController
  
  
  def show
    if @result = BerkeleyMapperResult.find(:first, :conditions => ["id = ?", params[:id]])
      render :text => @result.tabfile
    else
      render(:file => "#{Rails.root.to_s}/public/404.html", :status => "404 Not Found")
    end
  end




end
