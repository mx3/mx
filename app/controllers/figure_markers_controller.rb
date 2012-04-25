class FigureMarkersController < ApplicationController

  def create
    @figure_marker = FigureMarker.new(params[:figure_marker])
    @figure = Figure.find(params[:figure_id], :include => [:figure_markers])

    @figure_marker.figure = @figure
    if @figure_marker.save
      @figure.reload
      notice "Added SVG figure marker -- may want to AJAXIFY"
      redirect_to params[:return_to]
    else
      error "Error adding SVG figure marker -- may want to AJAXIFY"
      redirect_to params[:return_to]
    end
  end

  def destroy
    @figure_marker = FigureMarker.find(params[:id])
    @figure = @figure_marker.figure
    if @figure_marker.destroy
      notice "Removed SVG figure marker -- may want to AJAXIFY"
      redirect_to params[:return_to]
    else
      error "Error removing SVG figure marker"
      redirect_to params[:return_to]
    end
  end

  def edit
    @figure_marker = FigureMarker.find(params[:id])
    render :update do |page|
      page.hide 'add_marker'
      page.replace_html "figure_marker_#{@figure_marker.id}", :partial => "figure_marker/form", :locals => {:figure_marker => @figure_marker, :figure_id => @figure_marker.figure_id}
      # maybe color something different here
      # page.call 'updateSvgObjRoot', 'myroot2', @figure.svg
    end and return
  end

  def update
    @figure_marker = FigureMarker.find(params[:figure_marker_id])
    if @figure_marker.update_attributes(params[:figure_marker])
      notice "Updated SVG figure marker"
      redirect_to params[:return_to]
    else
      error "Error updating SVG figure marker"
      redirect_to params[:return_to]
    end
  end
end
