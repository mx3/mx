require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'account_controller'

class AccountController; def rescue_action(e) raise e end; end # Raise errors beyond the default web-based presentation

class AccountControllerTest < ActionController::TestCase
  
  self.use_instantiated_fixtures  = true # allows us to do @people['foo'] (which is a fixture *not* a Person)
  fixtures :people
  
  # An observation regarding passwords, using 'test01' as an example. Two different values are returned:
  #  Digest::SHA1.hexdigest() c25a79c57906ba7027b36d380230db92bbc0fd64
  #  sha1() = 2ccbc867d91a5f8c50362c03b32adaa26b70a593  
  # Therefor following the example that uses Digest::SHA1.hexdigest() in .yml fails here. ... ?Because
  # we use Digest::SHA1.hexdigest("foo#{pass}bar")- foo and bar should realy be randomized ultimately?
  
  # rewritten to work with fixtures
  
  def setup
    @controller = AccountController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    # request.host = "localhost"  # modified in application controller to handle 0.0.0.0 (bad??)
    # we do not use login() here because we need it to fail in some cases, and the function properly works only for success
  end
  
  def test_index
    get :index
    assert_redirected_to :action => "login"
  end
  
  def test_valid_login
    post :login, "person_login" => "test", "person_password" => "test01"
    assert(@response.has_session_object?(:person))
    assert_equal "Login successful", flash[:notice]
    
    assert_response(:redirect)
  end
  
  def test_admin_tester_login
    post :login, "person_login" => "test", "person_password" => "test01"
    
    assert_equal "Login successful", flash[:notice]
    assert_redirected_to :action => "list", :controller => 'proj' # we assume a root request (not necessarily the case)
    
    assert_not_nil(@response.session[:person])
    assert(@response.has_session_object?(:person))
    #    assert_session_has "person" 
    
    admin_tester = @people['admin_tester'].find
    assert_equal admin_tester, @response.session[:person]
    assert_equal @admin_tester, admin_tester # redundant, but an example of how things work
    assert_response(:redirect)
  end

  def test_failed_login
      post :login, "person_login" => "test", "person_password" => "test01aaa" 
      assert_equal "Login unsuccessful", flash[:notice]
      assert_nil(@response.session[:person])
  end

  def test_signup
    login # see test/helper
    post :signup, "person" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "newpassword" }
    assert(@response.has_session_object?(:person))
  end

  def test_bad_signup
    login
    post :signup, "person" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "wrong" }
    assert(assigns("person").errors.invalid?("password"))
    assert_response(:success)
    
    post :signup, "person" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "newpassword" }
    assert(assigns("person").errors.invalid?("login"))
    assert_response(:success)

    post :signup, "person" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "wrong" }
    person = assigns("person")
    
    %w(first_name last_name login password).each do |col|
      assert(person.errors.invalid?(col))
    end
    
    assert(!assigns("person").errors.invalid?("middle_name"))
    assert_response(:success)
  end

  def test_invalid_login
    post :login, "person_login" => "bob", "person_password" => "not_correct"
     
    #assert_session_has_no "person"
    assert(!@response.has_session_object?(:person))
    assert_equal "Login unsuccessful", flash[:notice]
    # assert_template_has "message"
    # assert_template_has "login"
    assert(@response.has_template_object?("login"))
  end
 
  def test_login_logoff
    test_admin_tester_login
       assert(@response.has_session_object?(:person))
       #    assert_session_has "person"

    get :logout
       assert(!@response.has_session_object?(:person))
       #assert_session_has_no "person"
  end

  # TODO: delete test, reset password test
end
