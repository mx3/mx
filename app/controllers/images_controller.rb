class ImagesController < ApplicationController
          
  auto_complete_for :image, :maker
  
  # Ajax search for popup
  # likely better placed in figures or images
  def search_list
     @descriptions = ImageDescription.find_for_auto_complete(params.merge(:proj_id => @proj.id))
     @obj = ActiveRecord::const_get(params[:fig_obj_class]).find(params[:fig_obj_id]) # creates variable objects TODO: needed?
     render(:layout => false, :partial => "image_description/search_list", :locals => {:obj => @obj})
  end

  # Filter methods in mx3 will take a list params, find results, then updated a method
  # def filter
  # end

  def index
    list
    render :action => 'list'
  end

  def list
   @image_description_pages, @descriptions = paginate :image_description, :per_page => 20, :include => [:image, :otu, :image_view], :order => "image_descriptions.image_id",
   :conditions => "image_descriptions.proj_id = #{@proj.id}"
    if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def list_by_id
    @images = @proj.images 
  end

  def _show_params
    id = params[:image][:id] if params[:image]
    id ||= params[:id]

    if params[:image] || params[:shared] # we are actually passed an image description id
      @image = (params[:shared] ? ImageDescription.find(params[:id]).image : ImageDescription.find(params[:image][:id]).image)
    else
      @image = Image.find(params[:id])    
    end
    @image_descriptions = @image.image_descriptions.by_proj(@proj)
    @with_figure_markers = @image.figures.with_figure_markers.by_proj(@proj)
  end 

  def show
    _show_params 
    if (@image_descriptions.size == 0) 
      flash[:notice] = "You don't have that image described for this project, try adding it first."
      redirect_to :action => :list and return
    end
    @show = ['default']
  end

  def show_figures
    _show_params
    @no_right_col = true
    @without_figure_markers = @image.figures.without_figure_markers.by_proj(@proj)
    render :action => :show
  end

  def show_figure_markers
    _show_params
    @no_right_col = true
    render :action => :show
  end

  def show_image_descriptions
    _show_params
    @no_right_col = true
    @image_description = ImageDescription.new
    render :action => :show
  end

  def new
    @image = Image.new
    @image.license = @proj.default_license
    @image_description = ImageDescription.new

    # needs some better checking
    @image_description.specimen = Specimen.find(params[:specimen_id]) if params[:specimen_id]
    @image_description.otu = Otu.find(params[:otu_id]) if params[:otu_id]
  end

  def create
    @image = Image.new(params[:image])
    @image_description = ImageDescription.new(params[:image_description])
    if params[:taxon_name]
      if params[:taxon_name][:id].to_i > 0  
        taxon_id = params[:taxon_name][:id]
       if Otu.find_by_taxon_name_id_and_proj_id(params[:taxon_name][:id], @proj.id)   
         @image_description.errors.add(:base, "There is already an OTU assciated with that taxon name. Use the existing OTU or manually create a new one.")
         flash[:notice] = "Failed to create image."
         render :action => 'new' and return
       end
     end
   end

    begin
      Image.transaction do
        @image.save!
        @image_description.image_id = @image.id
        @otu = Otu.create!(:taxon_name_id => params[:taxon_name][:id]) if taxon_id
        @image_description.otu_id = @otu.id if @otu # must always be present?
        @image_description.save!
        flash[:notice] = 'Image was successfully created.'
        redirect_to :action => 'show', :id => @image
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      flash[:notice] = 'Failed to create image.'
      render :action => 'new'
    end
  end

  def edit
    @image = Image.find(params[:id])

    # somewhat weak 
    if @image.image_descriptions.by_proj(@proj).size == 0
      flash[:notice] = "You don't have that image described for this project, try adding it first."
      redirect_to :action => :list and return
    end

  end

  def update
    @image = Image.find(params[:id])

    # somewhat weak 
    if @image.image_descriptions.by_proj(@proj).count == 0
      flash[:notice] = "You don't have that image described for this project, try adding it first."
      redirect_to :action => :list and return
    end

    if @image.update_attributes(params[:image])
      flash[:notice] = 'Image was successfully updated.'
      redirect_to :action => 'show', :id => @image
    else
      render :action => 'edit'
    end
  end

  def destroy
    if o = Image.find(params[:id])
      begin
        o.destroy 
        flash[:notice] =  "Image deleted."         
      rescue
        flash[:notice] =  "Can't delete image, you're likely using it in a figure, or it belongs to another project."         
      end
    else
      flash[:notice] =  "Can't find that image!" 
    end 
    redirect_to :action => :list
  end

  def auto_complete_for_image
    value = params[:term]
    if value.nil?
      redirect_to(:action => 'index', :controller => 'images') and return
    else
      val = value.split.join('%') 
      @ids = ImageDescription.find(:all,
                                  :joins => 'LEFT OUTER JOIN taxon_names t on otus.taxon_name_id = t.id',
                                  :conditions => 
                                  ["(images.id LIKE ? OR
                                    otus.name LIKE ? OR
                                    taxon_names.cached_display_name LIKE ? OR 
                                    labels.name LIKE ? OR 
                                    image_views.name LIKE ? OR
                                    t.cached_display_name LIKE ? OR
                                    images.user_file_name LIKE ?) AND
                                    image_descriptions.proj_id = ?",
                                    value.gsub(/\%/, ""),
                                    "%#{val}%",
                                    "%#{val}%",
                                    "%#{val}%",
                                    "%#{val}%",
                                    "%#{val}%",
                                    "%#{val}%", @proj.id], :include => [:image, {:otu => {:taxon_name => :parent}}, :label, :image_view], :order => 'images.id' )
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @images, :method => params[:method])
  end

  def browse_figure_markers
 
    if (@proj.figure_markers.length == 0)
      flash[:notice] = "Create some figure markers first!"
      redirect_to(:action => :index) 
    end and return

    if params[:id].blank?
      @image = @proj.images.with_figure_markers.first 
    else
      @image = Image.find(params[:id])
    end 

    @next = @proj.images.with_figure_markers.after_id(@image.id).first
    @previous = @proj.images.with_figure_markers.before_id(@image.id).first

  end

end
