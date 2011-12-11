class SharedController < ApplicationController
  def show_or_edit
    if params[:cntrller].blank? && params[:edit].blank?
      flash[:notice] = "Slow down there! You've clicked or navigated in some way that has confused mx."
      redirect_to :action => :index, :controller => :projs, :id => :proj_id and return
    end

    opts = {:proj_id => params[:proj_id], :controller => params[:cntrller], :action => :show, :id => params[params[:cntrller]][:id]}
    # lets you have two actions on one form (the picker)
    if params[:edit]
      opts[:action] = :edit
    else
      opts[:action] = :show
      opts.update(:shared => true) if params[:cntrller] == "image"
    end
    redirect_to(opts)
  end

end
