class FigureController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

  def move
    @figure = Figure.find(params[:figure][:id])
    begin
      if obj = ActiveRecord::const_get(@figure.addressable_type).find(params[:move_to_id]) 
        @figure.addressable_id = params[:move_to_id]
        @figure.save!
      else
        flash[:notice] = "Not a valid ID to move to!"
      end
      flash[:notice] = "Successfully moved the figure to a new class." 
    rescue
      flash[:notice] = "Figure NOT moved, there was a problem with the update." 
    end
     redirect_to :action => :annotate, :id => @figure.id
  end

  def test
    @figure_markers = FigureMarker.find(:all) 
  end
  
  def annotate
    @figure = Figure.find(params[:id])
  end

  def index
    list
    render :action => :list
  end

  def list_params
    @figure_pages, @figures = paginate :figure, :per_page => 20, :conditions => "(proj_id = #{@proj.id})", :order => 'image_id, updated_on'
  end
  
  def list
    list_params
    if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def list_by_scope
    if params[:arg]
      @figures = @proj.figures.send(params[:scope],params[:arg])
    else
      @figures = @proj.figures.send(params[:scope])
    end 
    @list_title = "Figures #{params[:scope].humanize.downcase}" 
    render :action => :list_simple
  end

  def show
    @figure = Figure.find(params[:id])
    respond_to do |format|
      format.html {}
      format.svg {render(:text => @figure.svg_doc, :type => 'image/svg+xml')}
    end
  end

  def show_zoom
    @size = params[:size].blank? ? :medium : params[:size].to_sym
    @figure = Figure.find(params[:id])
    render :layout => false
  end

  # Figure modal task
  # In the original code we only created and updated figures via the popup (=modal) form.
  def illustrate 
    @figure = Figure.new
    @image = Image.new
    @obj = ActiveRecord::const_get(params[:fig_obj_class]).find(params[:fig_obj_id]) # the Model to be figured
    @figures = @obj.figures
    render :layout => false
  end

  # keep this method CRUDY, at present it *not* hit, since whe hit create from the figure action
  def new
    @figure = Figure.new
    @image = Image.new
    @obj = ActiveRecord::const_get(params[:figure_obj_class]).find(params[:figure_obj_id]) # the Model to be figured
    @figures = @obj.figures
    render :layout => false
  end
 

  def update
    @figure = Figure.find(params[:id], :include => [:figure_markers, :image])

    if @figure.update_attributes(params[:figure])
      respond_to do |wants|
        wants.js {}
        wants.html { redirect_to :action => 'list' }
      end
      notice "Figured updated."
    else # didn't save the tag
      respond_to do |wants|
        wants.js { } # something different here ... 
        wants.html { redirect_to :action => 'list' }
      end
      notice "Failed to update figure." 
    end
  end

  def create
    @figure = Figure.new(params[:figure]) 
    @obj = ActiveRecord::const_get(params[:figure_obj_class]).find(params[:figure_obj_id]) 
    @figures = @obj.figures

    @figure.addressable = @obj
    @figure.image_id = params[:image_id]

    if @figure.save
      respond_to do |wants|
        wants.js {}
        wants.html { redirect_to :action => 'list' }
      end
      notice "Figured #{@obj.display_name}."
    else # didn't save the tag
      respond_to do |wants|
        wants.js { } # something different here ... 
        wants.html { redirect_to :action => 'list' }
      end
    end
  
  end

  def destroy
    @figure = Figure.find(params[:id])
    if @figure.destroy
      respond_to do |wants|
        wants.js { }
        wants.html { redirect_to :action => 'list' }
      end
      notice "Destroyed the figure."
    else 
      respond_to do |wants|
        wants.js { }
        wants.html { redirect_to :back => true } # ?
      end
      notice "Failed to destroy the figure."
    end
  end

  def up
    @figure = Figure.find(params[:id])  
    @figure.move_higher
    @figures = @figure.figured_obj.figures  
    respond_to do |wants|
      wants.js { render 'reorder' }
      wants.html {  } # ?
    end
  end
 
  def down
    @figure = Figure.find(params[:id])  
    @figure.move_lower
    @figures = @figure.figured_obj.figures  
    respond_to do |wants|
      wants.js { render 'reorder' }
      wants.html {  } # ?
    end
  end

  def create_all_for_content_by_otu
     if Figure.create_all_for_content_by_otu(params[:content_id], params[:otu_id])
      flash[:notice] = 'Done!'
     else 
      flash[:notice] = 'Something went wrong, figures not added'
    end

    redirect_to :back
  end

  def edit
    #  redirect_to :back
    @figure = Figure.find(params[:id])
  end

  # this is all ajax
  def update_marker
    #new Ajax.Request('/projects/32/figure/_update_markers/3424', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false;
    @figure = Figure.find(params[:figure_id], :include => [:figure_markers, :image])

    if @figure.update_attributes(params[:figure])
      render :update do |page|

#     page.call "foo"
#        debugger
      # remove all possible markers
#      rjs_remove_markers(@figure)
     
#    @figure.figure_markers.each do |fm|
#      # this needs to hit all child classes
#      page.call 'remove_element' "marker_{fm.id}"
#    end

#    @figure.figure_markers.each do |fm|
#      fm.element_array do |e|
#        page.call "add#{e.element_type}" e.element_attributes_for_js
#      end
#    end

#      page.call 'createSvgRoot', 'body', 'myroot', 500, 500 
#      page.call 'addPath', 'fooid', 'mypath', 'M45.146,545.833c277.083-12.5,529.167-237.5,277.083-12.5', '#000000', 'red', 3
    
#      page.call 'removeElement', 'mypath'
#      str2 = '<svg xmlns="http://www.w3.org/2000/svg" id="myRect8" width="100" height="100"><rect x="5" y="5" id="myRect4" rx="3" ry="10" width="15" height="15" fill="purple" stroke="yellow" stroke-width="2"/></svg>'
#      page.call 'createSvgObjRoot', 'body', 'myroot2', str2, 500, 500

 #     str3 = '<svg xmlns="http://www.w3.org/2000/svg" id="myRect8" width="100" height="100"><rect x="0" y="5" id="myRect4" rx="3" ry="10" width="15" height="15" fill="green" stroke="red" stroke-width="8"/></svg>'

      page.call 'updateSvgObjRoot', 'myroot2', @figure.svg 

#        str = '<rect x="15" y="15" id="myRect2" rx="3" ry="10" width="150" height="150" fill="green" stroke="yellow" stroke-width="8"/>'
#      page.call 'blorf', str 
#       str2 = '<svg xmlns="http://www.w3.org/2000/svg" id="myRect8" width="100" height="100"><rect x="5" y="5" id="myRect4" rx="3" ry="10" width="15" height="15" fill="purple" stroke="yellow" stroke-width="2"/></svg>'
       
#       page.replace_html "figure_#{@figure.id}_img", :partial => 'figure/svg', :locals => {:fig => @figure}
       # flash.discard
      end and return      
    else
      render :update do |page|
        page.visual_effect :shake, "annotations" 
        flash.discard
      end and return      
    end    
  end

  def draw
     @figure = Figure.find(params[:id])
     respond_to do |format|
      format.html {} # default .rhtml
      format.js { 
        render :update do |page|
          #  page.remove "fp_#{@obj.class.to_s}_#{@obj.id}" # get rid of the form (use an effect)

          #  page.delay(3) do
            # page.visual_effect :appear, "fl_#{@obj.class.to_s}_#{@obj.id}" # unhide the previously hidden Tag link
        end
        
        @foo = :back  # page.replace "fbin_#{@obj.class.to_s}_#{@obj.id}", render_figs_for_obj(@obj)
        # end 
      }
    end 
    @foo = :back 
  end
  
  def draw_save
    @figure = Figure.find(params[:id])
    if params[:clear]
      @figure.svg_txt = nil
      @figure.save!
    else
      if @figure.update_attributes!(params[:figure])
      else
        flash[:notice] = "There was a problem saving the overlay!"
        redirect_to :action => :draw, :id => @figure and return
      end
    end
    flash[:notice] = "Updated the figure."
    redirect_to :action => :show, :id => @figure.figured_obj, :controller => @figure.addressable_type.tableize.singularize
  end
  
  def find_images
     # Display images via reference to their description
     @image_descriptions = ImageDescription.find_for_auto_complete(params.merge(:proj_id => @proj.id))
     @obj = ActiveRecord::const_get(params[:fig_obj_class]).find(params[:fig_obj_id])  
     respond_to do |wants|
      wants.js {}   
      wants.html { } # What TODO here? 
     end
     render :layout => false
  end

  def sort_figure_markers
    id_to_find = params.keys.grep(/figure_markers_for/).first.split("_").last  # get the key with "sensus_for" so we can have the ontology_class_id
    params[params.keys.grep(/figure_markers_for/).first].each_with_index do |id, index|
      FigureMarker.update_all(['position=?', index+1], ['id=?', id])
    end
    respond_to do |format|
      format.html {}  # shouldn't be hitting this from anywhere yet
      format.js { 
        render :update do |page|
          # update the figure if being displayed
          page << "if($('myroot2')) {"   # have a sensu list on the page?
            page.call 'updateSvgObjRoot', 'myroot2', Figure.find(id_to_find).svg # @figure.svg 
          page << "}"
        end
      }
    end
  end

end
