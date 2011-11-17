class ImageDescriptionController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

  def index
    render :action => 'index'
  end

  def list
    redirect_to :action => :index
  end

  def show
    @image_description = ImageDescription.find(params[:id])
  end

  def new
    if @target == 'manage'
      @image_description = ImageDescription.new(:standard_view, 'otu_id' => otu_id)
    else
      @image_description = ImageDescription.new
    end
  end

  def destroy_from_image
    # ajax
    @image_description = ImageDescription.find(params[:id])
    @image = @image_description.image

    if @image_description.destroy
      flash[:notice] = "Destroyed"
    else
      flash[:notice] = "Problem destroying the image description"
    end

    @image_description = ImageDescription.new
    @image_descriptions = @image.image_descriptions.by_proj(@proj.id)
    if @image_descriptions.size == 0
      flash[:notice] = "You destroyed the last reference to this image in this project. If you don't add a new reference here, the image will be removed from this project when you leave this page."
    end

    render :layout => false, :partial => 'image_description/ajax_list_add'
  end

  def create
    # only used in ajax, there is no new form by itself (its tied to creating image->create as well)
    @image_description = ImageDescription.new(params[:image_description])
    @image_description.ontology_class_xref = params[:xref_bioportal_concept_id] # TODO: Kludge, resolve in model when forms are updated

    if params[:taxon_name]
      if not params[:taxon_name][:id].blank?
        taxon_id = params[:taxon_name][:id]
        if Otu.find_by_taxon_name_id_and_proj_id(params[:taxon_name][:id], @proj.id)
          @image_description.errors.add(:base, "There is already an OTU assciated with that taxon name. Use the existing OTU or manually create a new one.")
          flash[:notice] = "Failed to create image."
        end
      end
    end

    @otu = Otu.create!(:taxon_name_id => params[:taxon_name][:id]) if taxon_id
    @image_description.otu_id = @otu.id if @otu # must always be present
    @image_description.image_id = params[:image][:id]

    if @image_description.save
      flash[:notice] = 'Image description was successfully created.'
    else
      flash[:notice] = 'Could not save the record.'
    end

    @image = Image.find(params[:image][:id])
    @image_description = ImageDescription.new
    @image_descriptions = @image.image_descriptions.by_proj(@proj)

    render :layout => false, :partial => 'image_description/ajax_list_add'
  end

  def edit
    @image_description = ImageDescription.find(params[:id])
  end

  def update
    @image_description = ImageDescription.find(params[:id])

    @image_description.ontology_class_xref = params[:xref_bioportal_concept_id] # TODO: Kludge, resolve in model when forms are updated
    if @image_description.update_attributes(params[:image_description])
      flash[:notice] = 'ImageDescription was successfully updated.'

      if params[:update_and_next]
        @id = ImageDescription.find(:first, :conditions => ["proj_id = #{@proj.id} AND id > ?", @image_description.id], :order => 'id ASC')
        if @id
          redirect_to(:action => 'edit', :id => @id)
        else
          flash[:notice] = 'Last record reached.'
          redirect_to(:action => 'list', :controller => 'image')
        end
      else
        redirect_to :action => :show, :id => @image_description.image.id, :controller => :image
      end
    else
      render :action => 'list', :controller => :image
    end
  end

  def destroy
    ImageDescription.find(params[:id]).destroy
    redirect_to :action => :list, :controller => :image
  end

  def more
    if @image_description = ImageDescription.find(params[:id])
      render(:partial => 'image_description/more', :layout => false )  # htmlize from application_helper not available here
    else
      flash[:notice] = "Something went wrong when trying to see more."
      render :action => 'index'
    end
  end

  def add
    # can merge this with add_list , but careful, there are 2 different ajax calls, the search, and the add
    @ids = []
    # @existing_images = @proj.image_descriptions.collect{|i| i.image_id}.uniq
  end

  def add_list
    if request.xml_http_request?
      if params[:add] # add the image description
        if @new_id = ImageDescription.add_from_project(params.merge(:proj_id => @proj.id)     )
          render :update do |page|
            page.replace_html params[:form], :text => '<div class="box1" style="margin-top: 1em;"> <i> You added this image to your project! </i></div> '
          end and return
        else
          render :update do |page|
            page.visual_effect :shake,  params[:form]
          end and return
        end
      end

      id = params[:proj_to_search_a][:id] if params[:proj_to_search_a]
      id ||= params[:proj_to_search]
      @image_description_pages, @ids = paginate :image_description, :per_page => 20, :include => [:image, :otu, :label, :image_view], :order => "image_descriptions.image_id",
        :conditions => "image_descriptions.proj_id = #{id}"

      @existing_images = @proj.image_descriptions.collect{|i| i.image_id}.uniq
      render(:layout => false, :partial => 'add_list', :locals => {:proj_to_search => id})
    end

  end

  # dumb
  def less
    render :text => "", :layout => false
  end

  def summarize

    render :action => :index and return if !request.post?

    if params[:view][:otu_group_id].blank? && params[:view][:standard_view_group_id].blank?
      flash[:notice] = 'Include an OTU group OR a standard-view group'
      @target = ''
      render :action => 'index' and return
    end

    if params[:view][:otu_group_id].blank? # show by view
      @standardviewgroup = StandardViewGroup.find(params[:view][:standard_view_group_id])
      @standard_views = @standardviewgroup.standard_views

      @img_descrs = @standard_views.inject([]){|sum, o| sum += o.image_descriptions}

      @header ='Standard view group'
      render :action => 'browse_list'

    elsif  params[:view][:standard_view_group_id].empty? # show by otu_group
      @otugroup = OtuGroup.find(params[:view][:otu_group_id])
      @otus = @otugroup.otus

      @img_descrs = @otus.inject([]){|sum, o| sum += o.image_descriptions(@proj.id)}

      @header = 'OTU group'
      render :action => 'browse_list'

    else # show OTU group X standard view group
      @otugroup = OtuGroup.find(params[:view][:otu_group_id])
      @otus = @otugroup.otus

      @standardviewgroup = StandardViewGroup.find(params[:view][:standard_view_group_id])
      @standard_views = @standardviewgroup.standard_views

      if @otus.empty? or @standard_views.empty?
        flash[:notice] = 'Hmm... one (or both) of your groups is empty, given them some members and try again!'
        @target = ''
        render :action => 'index' and return
      end
      render :action => 'browse_table'
    end
  end

end
