require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

# Re-raise errors caught by the controller.
class ImagesController; def rescue_action(e) raise e end; end

class ImagesControllerTest < ActionController::TestCase
  def setup
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
    @controller = ImagesController.new
    opts = {:proj_id => 1}
    super
  end

  test "autocompleter for images on copyright_holder" do
    images = ('a'..'f').map do |pre|
      [Image.make!(:proj => @proj, :creator => @p,  :copyright_holder => pre   ),
       Image.make!(:proj => @proj, :creator => @p,  :copyright_holder => pre*2 ),
       Image.make!(:proj => @proj, :creator => @p,  :copyright_holder => pre*3 )
      ]
    end.flatten

    get :auto_complete_for_images, :proj_id => @proj.id, :field => 'copyright_holder'
    assert_response :bad_request

    get :auto_complete_for_images, :proj_id => @proj.id, :field => 'copyright_holder', :term=>'a'
    assert_response :success
    assert_equal 3, ActiveSupport::JSON.decode(@response.body).size

    get :auto_complete_for_images, :proj_id => @proj.id, :field => 'copyright_holder', :term=>'aa'
    assert_response :success
    assert_equal 2, ActiveSupport::JSON.decode(@response.body).size

    get :auto_complete_for_images, :proj_id => @proj.id, :field => 'copyright_holder', :term=>'aaa'
    assert_response :success
    assert_equal 1, ActiveSupport::JSON.decode(@response.body).size
  end

  test "autocompleter for images on maker" do
    images = ('a'..'f').map do |pre|
      [Image.make!(:proj => @proj, :creator => @p,  :maker => pre   ),
       Image.make!(:proj => @proj, :creator => @p,  :maker => pre*2 ),
       Image.make!(:proj => @proj, :creator => @p,  :maker => pre*3 )
      ]
    end.flatten

    get :auto_complete_for_images, :proj_id => @proj.id, :field => 'maker'
    assert_response :bad_request

    get :auto_complete_for_images, :proj_id => @proj.id, :field => 'maker', :term=>'a'
    assert_response :success
    assert_equal 3, ActiveSupport::JSON.decode(@response.body).size

    get :auto_complete_for_images, :proj_id => @proj.id, :field => 'maker', :term=>'aa'
    assert_response :success
    assert_equal 2, ActiveSupport::JSON.decode(@response.body).size

    get :auto_complete_for_images, :proj_id => @proj.id, :field => 'maker', :term=>'aaa'
    assert_response :success
    assert_equal 1, ActiveSupport::JSON.decode(@response.body).size
  end
end
