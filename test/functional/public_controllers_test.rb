require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'public/refs_controller'

class  Public::RefsController; def rescue_action(e) raise e end; end # Raise errors beyond the default web-based presentation
class  Public::RefsControllerTest < ActionController::TestCase

  # test routes here?

  def setup
    @person = Person.create!(:login => 'foo2323', :last_name => "Enstein", :first_name => "Frank", :password => "rumplistillskin", :email => "foo@bar.com")
    $person_id = @person.id # this is set at login, we dummy it in here
    assert @person
  end

  def teardown
    session = nil
  end

  ['test.com', 'www.test.com'].each do |base_url|
     # www is stripped, then test becomes the pointer to the /public folder
    test "that public routes for projects with a public server name work on #{base_url}" do
      @controller = Public::RefsController.new
      @request =    ActionController::TestRequest.new
      @response =   ActionController::TestResponse.new


      # setup
      @proj_new = Proj.create!(:name => "foo", :unix_name => 'bar', :public_server_name => 'test.com', :public_controllers => ["otus", "refs", "home"] )
      assert @proj_new
      assert_equal "foo", @proj_new.name
      assert_equal "test", @proj_new.site
      assert_equal @person.id, @proj_new.creator_id
      # make the request come from a remote address

      @request.env["REMOTE_ADDR"] = base_url
      @request.env["SERVER_NAME"] = base_url

      opts = {:controller => "public/refs", :action => "index", :proj_id => "#{@proj_new.id}"}

      assert_recognizes opts, "projects/#{@proj_new.id}/public/refs"
      assert_routing "projects/#{@proj_new.id}/public/refs", opts

      get :index, opts # was list
      assert_response(:success)
    end
  end
end
