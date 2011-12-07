class PublicContentsController < ApplicationController
    
  def index
    list
    render :action => 'list'
  end

  def list
    @otus = @proj.otus.with_published_content
    @display_data = ByTnDisplay.new(nil, @otus)
  end

  def unpublish
    if o = Otu.find(params[:id])
      for c in Content.by_otu(o).that_are_published
        c.destroy 
      end
      flash[:notice] = 'Unpublished!'
    else
      flash[:notice] = 'Failed!'
       # raise "can't unpublish content for that OTU, it couldn't be found"
    end
     redirect_to :action => :list
  end
  
  def show
    redirect_to :action => :show_content, :controller => :otus, :id => params[:id]
  end
  
end
