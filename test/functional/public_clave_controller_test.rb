require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


require 'public/clave_controller'

# Re-raise errors caught by the controller.
class Public::ClaveController; def rescue_action(e) raise e end; end
class Public::ClaveControllerTest < ActionController::TestCase
  
  def setup
    @controller = Public::ClaveController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  
    @pub_base_urls = ['test.com', 'www.test.com'] # www is stripped, then test becomes the pointer to the /public folder
    
    @person = Person.create!(:login => 'foo2323', :last_name => "Enstein", :first_name => "Frank", :password => "rumplistillskin", :email => "foo@bar.com")
    $person_id = @person.id # this is set at login, we dummy it in here
    assert @person
    @proj_new = Proj.create!(:name => "foo", :unix_name => 'blorf', :public_server_name => 'test.com', :public_controllers => ["clave"] )
    
    # note this only tests without data, i.e. won't detect problems with list etc. (at present)

  end

  def test_index
   @pub_base_urls.each do |base_url|
          opts = {:controller => "public/clave", :action => "index", :proj_id => "#{@proj_new.id}"}
          get :index, opts   
          assert_response(:success)
    end
  end

  def test_routes
    @pub_base_urls.each do |base_url|
          # make the request come from a remote address
          @request.env["REMOTE_ADDR"] = base_url
          @request.env["SERVER_NAME"] = base_url

          opts = {:controller => "public/clave", :action => "index", :proj_id => "#{@proj_new.id}"}

          assert_recognizes opts , "projects/#{@proj_new.id}/public/clave"
          assert_routing "projects/#{@proj_new.id}/public/clave", opts
    end
  end


end

