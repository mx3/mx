class Api::FigureController < ApplicationController

  def index
    redirect_to "http://#{HELP_WIKI}/index.php/App/API/Figure" and return
  end

  def show
    if @figure = Figure.find(params[:id])
      respond_to do |format|
        format.html {redirect_to :action => :index}
        format.svg {render(:text => @figure.svg_doc, :type => 'image/svg+xml')}
      end
    else
      render :file => "#{Rails.root}/public/404.html", :status => :not_found and return 
    end
  end

end
