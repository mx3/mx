require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'images_controller'

# Re-raise errors caught by the controller.
class ImagesController; def rescue_action(e) raise e end; end

class ImagesControllerTest < ActionController::TestCase
  fixtures :images

  def setup
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
    @controller = ImagesController.new
    opts = {:proj_id => 1}
  end

  def test_create
   #  post :create, :image => {
     #   :file => fixture_file_upload('/files/img_1.jpg', 'image/png')
     # }, :proj_id => 1, :taxon_name => 1
     # assert_response :success
    
   # assert_equal "Image was successfully created.", flash[:notice] 
    
  end

end
