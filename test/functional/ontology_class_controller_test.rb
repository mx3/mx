require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class OntologyClassControllerTest < ActionController::TestCase
  def setup
     $person_id = 1
     $proj_id = 1

     # make sure we're living in the universe described below
     @proj = Proj.find($proj_id)
     @proj.ontology_classes.destroy_all 

     @ref = Ref.create!(:title => "Bar")
     @ontology_class = OntologyClass.create!(:definition => "The blorf that is bar.", :written_by => @ref)
     @proj.reload

     ObjectRelationship.create!(:interaction => 'is_a')
     ObjectRelationship.create!(:interaction => 'part_of')

     @opts = {:proj_id => "1"}
     login
   end

   test "should get index" do
     get :index, @opts
     assert_response :success
     assert_not_nil assigns(:ontology_classes)
   end

   test "should get new" do
     get :new, @opts
     assert_response :success
   end

   test "should create ontology_class" do
     assert_difference('OntologyClass.count') do
       post :create, @opts.merge!(:ontology_class => {:written_by => @ref, :definition => "Blorf in the foo."})
     end
     assert_redirected_to :controller => :ontology_class, :action => :show, :id => assigns(:ontology_class) # @ontology_class # "http://test.host/projects/1/ontology_class/show/" # ontology_class_path(assigns(:ontology_class))
   end

   test "should show ontology_class" do
     get :show, @opts.merge!(:id => @ontology_class.id)
     assert_response :success
   end

   test "should get edit" do
     get :edit, @opts.merge!(:id => @ontology_class.id)
     assert_response :success
   end

   test "should update ontology_class" do
     put :update, @opts.merge!(:id => @ontology_class.id, :ontology_class => {:definition => "New definition"})
     assert_redirected_to :action => :show, :controller => :ontology_class, :id => @ontology_class.id # assigns(:ontology_class)

     # assert_redirected_to # ontology_classes_path(assigns(:ontology_class))   # not yet RESTful
   end

   test "should destroy ontology_class" do
     assert_difference('OntologyClass.count', 0) do
       delete :destroy, @opts.merge(:id => @ontology_class.id)
     end
       assert_redirected_to :controller => "ontology_class", :action => "list"  
   end

end
