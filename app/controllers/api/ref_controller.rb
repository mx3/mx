
class Api::RefController < ApplicationController

  def index
    redirect_to "http://#{HELP_WIKI}/index.php/App/API/Ref" and return
  end

  def show

    if @ref = Ref.find(params[:id])
      # respond_to do |format|
      #  format.html {
      render(:text => @ref.display_name, :type => 'text/plain') and return
      #  }
      #  format.svg {render(:text => @figure.svg_doc, :type => 'image/svg+xml')}
      #end
    else
      render :file => "#{Rails.root}/public/404.html", :status => :not_found and return 
    end
  end

end
