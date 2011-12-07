require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class SensusControllerTest < ActionController::TestCase
  def setup
    # instead of fixtures mock some data
    $person_id = 1
    $proj_id = 1

    # make sure we're living in the universe described below
    @proj = Proj.find($proj_id)
    @proj.sensus.destroy_all 

    @label = Label.create!(:name => "Foo")
    @ref = Ref.create!(:title => "Bar")
    @ref2 = Ref.create!(:title => "Smorf")
    @ontology_class = OntologyClass.create!(:definition => "The blorf that is bar.", :written_by => @ref)

    @sensu = Sensu.create!(:ref => @ref, :label => @label, :ontology_class => @ontology_class) 
    
    @proj.reload

    @opts = {:proj_id => "1"}
    login
  end

  test "should get index" do
    get :index, @opts
    assert_response :success
    assert_not_nil assigns(:sensus)
  end

  test "should get new" do
    get :new, @opts
    assert_response :success
  end

  test "should create sensu" do
    assert_difference('Sensu.count') do
      post :create, @opts.merge!(:sensu => {:ref => @ref2, :label => @label, :ontology_class => @ontology_class})
    end
    assert_redirected_to :controller => :sensus, :action => :show, :id => assigns(:sensu) # @sensu # "http://test.host/projects/1/sensu/show/" # sensu_path(assigns(:sensu))
  end

  test "should show sensu" do
    get :show, @opts.merge!(:id => @sensu.id)
    assert_response :success
  end

  test "should get edit" do
    get :edit, @opts.merge!(:id => @sensu.id)
    assert_response :success
  end

  test "should update sensu" do
    put :update, @opts.merge!(:id => @sensu.id, :sensu => {:notes => "New note"})
    assert_redirected_to :action => :show, :controller => :sensus, :id => @sensu.id # assigns(:sensu)
  
    # assert_redirected_to # sensus_path(assigns(:sensu))   # not yet RESTful
  end

  test "should destroy sensu" do
    assert_difference('Sensu.count', -1) do
      delete :destroy, @opts.merge(:id => @sensu.id)
    end
    assert_redirected_to :controller => :sensus, :action => "index"
  end

end
