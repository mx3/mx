class MeasurementsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list
    @measurement_pages, @measurements = paginate :measurement, :per_page => 20,
    :conditions => ['proj_id = (?)', @proj.id]

     if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def show
    @measurement = Measurement.find(params[:id])
  end

  def new
    @measurement = Measurement.new
  end

  def create
    @measurement = Measurement.new(params[:measurement])
    if @measurement.save
      flash[:notice] = 'Measurement was successfully created.'
        
      if params[:commit] == "Create and new"
          (@specimen = Specimen.find(params[:measurement][:specimen_id])) if params[:lock][:specimen] == '1'
          (@standard_view = StandardView.find(params[:measurement][:standard_view_id])) if params[:lock][:standard_view] == '1'
          (@units = params[:measurement][:units]) if params[:lock][:units] == '1'
          (@conversion_factor = params[:measurement][:conversion_factor]) if params[:lock][:conversion_factor] == '1'
          
        @measurement = Measurement.new
        render :action => 'new' and return
      else 
        redirect_to :action => 'list'    
      end

    else
      render :action => 'new'
    end
  end

  def edit
    @measurement = Measurement.find(params[:id])
  end

  def update
    @measurement = Measurement.find(params[:id])
    if @measurement.update_attributes(params[:measurement])
      flash[:notice] = 'Measurement was successfully updated.'
      redirect_to :action => 'show', :id => @measurement
    else
      render :action => 'edit'
    end
  end

  def destroy
    Measurement.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def batch_new

    respond_to do |format|
      format.js { 

        @standard_view_group = StandardViewGroup.find(params[:measurement_batch][:standard_view_group_id], :include => :standard_views)
        @otu = Otu.find(params[:measurement_batch][:otu_id])
        @units = params[:measurement_batch][:units]
        @conversion_factor = params[:measurement_batch][:conversion_factor]

        @specimens = @otu.specimens_most_recently_determined_as
        render :update do |page| 
          if @specimens.size == 0
            page.replace_html :results, :text => 'OTU had no specimens, choose another.'
          else
            page.replace_html :results, :partial => 'batch_create_form'
          end
        end and return
      }
      format.html {
        @conversion_factor = 1
      }

    end

  end


  def batch_create
    # this is a create/update merge
    begin
      Measurement.transaction do 
        params[:specimens].keys.each do |k|
          s = Specimen.find(k) 
          s.update_attributes(params[:specimens][k])
        end
      end
     flash[:notice] = "Successfully added/updated measurements"
    rescue
      flash[:notice] = "Error adding measurements."
    end
   
    redirect_to :action => :batch_new and return
  end



end
