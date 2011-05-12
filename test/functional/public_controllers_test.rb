require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'public/ref_controller'

class  Public::RefController; def rescue_action(e) raise e end; end # Raise errors beyond the default web-based presentation

  class  Public::RefControllerTest < ActionController::TestCase

    # test routes here?

    def setup
      @person = Person.create!(:login => 'foo2323', :last_name => "Enstein", :first_name => "Frank", :password => "rumplistillskin", :email => "foo@bar.com")
      $person_id = @person.id # this is set at login, we dummy it in here
      assert @person
    end

    def teardown
      session = nil
    end

    def test_that_public_routes_for_projects_with_a_public_server_name_work
      @controller = Public::RefController.new
      @request =    ActionController::TestRequest.new
      @response =   ActionController::TestResponse.new
     
      pub_base_urls = ['test.com', 'www.test.com'] # www is stripped, then test becomes the pointer to the /public folder

      # setup
      @proj_new = Proj.create!(:name => "foo", :unix_name => 'bar', :public_server_name => 'test.com', :public_controllers => ["otu", "ref", "home"] )
      assert @proj_new
      assert_equal "foo", @proj_new.name
      assert_equal "test", @proj_new.site
      assert_equal @person.id, @proj_new.creator_id

      pub_base_urls.each do |base_url|
        # make the request come from a remote address
        @request.env["REMOTE_ADDR"] = base_url
        @request.env["SERVER_NAME"] = base_url

        opts = {:controller => "public/ref", :action => "index", :proj_id => "#{@proj_new.id}"}

        assert_recognizes opts , "projects/#{@proj_new.id}/public/ref"
        assert_routing "projects/#{@proj_new.id}/public/ref", opts
        

        get :list, opts   
        assert_response(:success)
      end

    end
  end
