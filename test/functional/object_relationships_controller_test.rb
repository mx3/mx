require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class ObjectRelationshipsControllerTest < ActionController::TestCase
  def setup
     # instead of fixtures mock some data
     $person_id = 1
     $proj_id = 1

     # make sure we're living in the universe described below
     @proj = Proj.find($proj_id)
     @proj.object_relationships.destroy_all 

     @object_relationship = ObjectRelationship.create!(:interaction => "foos")
     @proj.reload

     @opts = {:proj_id => "1"}
     login
   end

   test "should get index" do
     get :index, @opts
     assert_response :success
     assert_not_nil assigns(:object_relationships)
   end

   test "should get new" do
     get :new, @opts
     assert_response :success
   end

   test "should create object_relationship" do
     assert_difference('ObjectRelationship.count', 1) do
       post :create, @opts.merge!(:object_relationship => {:interaction => "bars"})
     end
     assert_redirected_to :controller => :object_relationships, :action => :show, :id => assigns(:object_relationship) # @object_relationship # "http://test.host/projects/1/object_relationship/show/" # object_relationship_path(assigns(:object_relationship))
   end

   test "should show object_relationship" do
     get :show, @opts.merge!(:id => @object_relationship.id)
     assert_response :success
   end

   test "should get edit" do
     get :edit, @opts.merge!(:id => @object_relationship.id)
     assert_response :success
   end

   test "should update object_relationship" do
     put :update, @opts.merge!(:id => @object_relationship.id, :object_relationship => {:interaction => "blorfs"})
     assert_redirected_to :action => :show, :controller => :object_relationships, :id => @object_relationship.id # assigns(:object_relationship)

     # assert_redirected_to # object_relationships_path(assigns(:object_relationship))   # not yet RESTful
   end

   test "should destroy object_relationship" do
     assert_difference('ObjectRelationship.count', -1) do
       delete :destroy, @opts.merge(:id => @object_relationship.id)
     end
       assert_redirected_to :controller => :object_relationships, :action => "list"
   end

end
