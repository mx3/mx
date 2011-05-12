class Public::ImageController < Public::BaseController
  
  def index
    list
    render :action => 'list'
  end

  def list
   @image_description_pages, @descriptions = paginate :image_description, :per_page => 20, :include => [:image, :otu,:image_view], :order => "image_descriptions.image_id",
   :conditions => "image_descriptions.proj_id = #{@proj.id} AND is_public = true"
 end

  def show
    @image = Image.find(params[:id])
    @image_descriptions = @image.image_descriptions
  end
  
end
