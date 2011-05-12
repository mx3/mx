class Public::FigureController < ApplicationController
 
  def show_zoom
    @size = params[:size].blank? ? :medium : params[:size].to_sym
    @figure = Figure.find(params[:id])
    render :layout => false
  end

end
