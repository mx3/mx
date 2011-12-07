require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class LabelsControllerTest < ActionController::TestCase

  def setup
    # instead of fixtures mock some data
    $person_id = 1
    $proj_id = 1

    # make sure we're living in the universe described below
    @proj = Proj.find($proj_id)
    Label.destroy_all 

    @label = Label.create!(:name => "Foo")

    @proj.reload

    @opts = {:proj_id => "1"}
    login
  end

  test "should get index" do
    get :index, @opts
    assert_response :success
    assert_not_nil assigns(:labels)
  end

  test "should get new" do
    get :new, @opts
    assert_response :success
  end

  test "should create label" do
    assert_difference('Label.count') do
      post :create, @opts.merge(:label => {:name => 'Blorf' })
    end

    assert_redirected_to :controller => :labels, :action => :show, :id => assigns(:label)
    #assert_redirected_to label_path(assigns(:label))
  end

  test "should show label" do
    get :show, @opts.merge!(:id => @label) 
    assert_response :success
  end

  test "should get edit" do
    get :edit, @opts.merge(:id => @label) 
    assert_response :success
  end

  test "should update label" do
    put :update, @opts.merge!(:id => @label.id, :label => {:active_on => Time.now })
    assert_redirected_to :action => :show, :controller => :labels, :id => @label.id

    # assert_redirected_to label_path(assigns(:label))
  end

  test "should destroy label" do
    assert_difference('Label.count', -1) do
      delete :destroy, @opts.merge(:id => @label.id) 
    end

    assert_redirected_to :controller => "labels", :action => "list"
  end
end
