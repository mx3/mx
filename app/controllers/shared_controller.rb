class SharedController < ApplicationController

  def show_or_edit
    if params[:cntrller].blank? && params[:edit].blank?
      flash[:notice] = "Slow down there! You've clicked or navigated in some way that has confused mx."
      redirect_to :action => :index, :controller => :projs, :id => :proj_id and return
    end

    # lets you have two actions on one form (the picker)
    if params[:edit]
      redirect_to(:controller => params[:cntrller], :action => :edit, :id => params[params[:cntrller]][:id] ) and return
    else
      
      opts = {:controller => params[:cntrller], :action => :show, :id => params[params[:cntrller]][:id]}

      opts.update(:shared => true) if params[:cntrller] == "image"
      redirect_to(opts) and return
    end
  end
  
end
