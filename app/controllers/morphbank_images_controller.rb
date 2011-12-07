include RubyMorphbank

class MorphbankImagesController < ApplicationController

  def new
    @morphbank_image = MorphbankImage.new
    @image_description = ImageDescription.new
    @target = 'new'
  end

  def create
    @morphbank_image = MorphbankImage.new(params[:morphbank_image])
    @mb_img_desc = ImageDescription.new(params[:image_description])
    begin
      @morphbank_image.save!
      @mb_img_desc.image_id = @morphbank_image.id
      @mb_img_desc.save!
     
     flash[:notice] = "Added the Morphbank image."
     redirect_to :action => :show, :id => @morphbank_image.id, :controller => :images and return
    rescue ActiveRecord::RecordInvalid => e
      flash[:notice] = "#{e}"
      redirect_to :action => 'new' and return
    end
    redirect_to  :controller => 'images', :action => 'index'
  end

  def edit
    @morphbank_image = MorphbankImage.find(params[:id])
    @target = 'edit'
    if  @morphbank_image == nil
      flash[:notice] = 'Problem finding the morphbank image.'
      redirect_to :action => 'list', :controller => 'images' and return
    end
  end

  def update
    @morphbank_image = MorphbankImage.find(params[:id])
    if @morphbank_image.update_attributes(params[:morphbank_image])
      flash[:notice] = 'Image links was successfully updated.'
      redirect_to :action => 'show', :id => @morphbank_image, :controller => 'images'
    else
      render :action => 'edit'
    end
  end

  def show
    redirect_to :action => :show, :id => params[:id], :controller => :images
  end

  ## MB batch upload ##

  def MB_batch_load
  end

  # logic to model? 
  def MB_batch_verify
    if params[:temp_file][:file].blank?
      flash[:notice] = "Choose a text file with your images in it before verifying!"
      redirect_to(:action => :MB_batch_load) and return  
    end

    # read the contents of the uploaded file, split on pairs of newlines or '---', strip each one and add a newline
    imgs = params[:temp_file][:file].read.split(/\n/).map{|x| x.strip.split(/\t/)}
    @images = []
    @existing = []
    imgs.each do |i| 
      if Image.find(:first, :conditions => ["mb_id = ? AND proj_id = ?", i[0].to_i , @proj.id])
        @existing.push([i[0], i[1]])
      else
        if o = Otu.find(:first, :conditions => ["name = ? and proj_id = ?", i[1].to_s, @proj.id] )

          @images.push([i[0], o])
        else
          @existing.push([i[0], i[1]])
        end 
      end
    end
  end

  def MB_batch_create
    @count = 0

    begin
      Image.transaction do
        for p in params[:img].keys
          if params[:check][p]
            @mb_img = MorphbankImage.new(:mb_id => params[:img][p])
            @mb_img_desc = ImageDescription.new(:otu_id => params[:otu][p])

            @mb_img.save!
            @mb_img_desc.image_id = @mb_img.id
            @mb_img_desc.save!
            @count += 1
          end
        end
      end

    rescue
      flash[:notice] = "Something went wrong."
      redirect_to :action => :MB_batch_load and return
    end

    flash[:notice] = "Successfully added #{@count} images." 
    redirect_to :action => :MB_batch_load
  end

  # MB search/add cart
  def search
    respond_to do |format|
      format.html { 
        render :action => :search and return
      }
      format.js {
        # uses rubyMorphbank gem
        x = Rmb.new.request(:keywords => params[:keywords]).get_response
        @keywords = params[:keywords] 
        @first_result = x.get_int('firstResult')
        @num_results_returned = x.get_int('numResultsReturned')
        @num_results = x.get_int('numResults')
        @mb_image_ids = x.mb_image_ids
        @lnk_fwd = x.link_forward?
        @lnk_bck = x.link_back?

        render :update do |page|
          page.replace_html :runner, :partial => "morphbank_image/runner"
          page.replace_html :cart_form, :partial => "morphbank_image/form_for_cart"
          flash.discard
        end and return
      }
    end
  end

  def navigate
    req = nil
    case params[:direction]
    when 'fwd'
      req = Rmb.new.request(:format => 'id', :keywords => params[:keywords], :firstResult => (params[:first_result].to_i + params[:num_results_returned].to_i))
    when 'bck'
      req = Rmb.new.request(:format => 'id', :keywords => params[:keywords], :firstResult => (params[:first_result].to_i - params[:num_results_returned].to_i), :limit => params[:num_results_returned])
    when 'start'
      req = Rmb.new.request(:format => 'id', :keywords => params[:keywords], :firstResult => 0, :limit => params[:num_results_returned])
    when 'end'
      req = Rmb.new.request(:format => 'id', :keywords => params[:keywords], :firstResult => (params[:num_results].to_i - params[:num_results_returned].to_i))
    end

    # uses rubyMorphbank gem
    x = req.get_response
    @keywords = params[:keywords] # though we could get this out of x it's simpler reference in the view
    @first_result = x.get_int('firstResult')
    @num_results_returned = x.get_int('numResultsReturned')
    @num_results = x.get_int('numResults')
    @mb_image_ids = x.mb_image_ids
    @lnk_fwd = x.link_forward?
    @lnk_bck = x.link_back?

    respond_to do |format|
      format.html { 
        render :action => :search and return
      }
      format.js {
        render :update do |page|
        page.replace_html :runner, :partial => "morphbank_image/runner"
        flash.discard
        end and return        
      }
    end
  end

  def _set_otu_for_mb_cart
    @otu = Otu.find(params[:otu][:id], :include => :image_descriptions)
    respond_to do |format|
      # shouldn't hit here
      format.html { 
        render :action => :search and return
      }
      format.js {
        render :update do |page|
        page.replace_html :otu_cart, :partial => "morphbank_image/add_cart" 
        flash.discard
        end and return        
      }
    end
  end

  def _add_thumb
    @otu = Otu.find(params[:otu_id])
    mb_id = params[:id].split("_")[1]

    # search and don't allow for dupes
    if @otu.has_image_of_mb_id(mb_id).size == 0

      begin
        Image.transaction do
          @mb_img = MorphbankImage.new(:mb_id => mb_id)
          @mb_img_desc = ImageDescription.new(:otu_id => @otu.id )

          @mb_img.save!
          @mb_img_desc.image_id = @mb_img.id
          @mb_img_desc.save!
        end

      rescue
        flash[:notice] = "Something went wrong."
      end
      flash[:notice] = "Added the image with mb_id #{mb_id}."
    else    
      flash[:notice] = "Image with mb_id #{mb_id} already added for this OTU."
    end

    respond_to do |format|
      # shouldn't hit here
      format.html { 
        render :action => :search and return
      }
      format.js {
        render :update do |page|
        page.replace_html :attached_images, :partial => 'morphbank_image/search_list', :locals => {:notice => flash[:notice]}
        flash.discard
        end and return        
      }
    end

    # shouldn't hit here unless something has gone very wrong
    render :action => :search, :controller => :morphbank_images
  end

end
