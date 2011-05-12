class FigureMarkerController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

  def create
    @figure_marker = FigureMarker.new(params[:figure_marker])
    @figure = Figure.find(params[:figure_id], :include => [:figure_markers])

    @figure_marker.figure = @figure 
    if @figure_marker.save 
      @figure.reload
      render :update do |page|
        page.show 'add_marker'
        page.remove "fm_form_new"
        page.insert_html :bottom, "figure_markers_for_figure_#{@figure_marker.figure_id}", :partial => "figure_marker/fm", :object => @figure_marker
       
        page.call 'updateSvgObjRoot', "fig_svg_root_#{@figure.id}", @figure.svg 
      end and return      
    else
      render :update do |page|
        page.visual_effect :shake, "fm_form_new" 
        flash.discard
      end and return      
    end    
  end

  def destroy
    @figure_marker = FigureMarker.find(params[:id])
    @figure = @figure_marker.figure
    if @figure_marker.destroy
      render :update do |page|
        page.remove "figure_marker_#{@figure_marker.id}"
        page.call 'updateSvgObjRoot', "fig_svg_root_#{@figure_marker.figure_id}", @figure.svg 
      end and return      
    else
      render :update do |page|
        page.visual_effect :shake, "fm_form_new" # something else here
        flash.discard
      end and return      
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
      render :update do |page|
        page.show 'add_marker'
        page.replace_html "fm_form_#{@figure_marker.id}", :partial => "figure_marker/fm", :object => @figure_marker
        page.call 'updateSvgObjRoot', "fig_svg_root_#{@figure_marker.figure_id}", Figure.find(@figure_marker.figure_id).svg 

        # page.call 'createSvgObjRoot', (request.xml_http_request? ? 'ajax' : 'http'), *figure.svgObjRoot_params(:medium)

      end and return
    else
      render :update do |page|
        page.shake "figure_marker_#{@figure_marker.id}"
      end and return
    end

  end

end
