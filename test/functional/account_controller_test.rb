require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'account_controller'

class AccountController; def rescue_action(e) raise e end; end # Raise errors beyond the default web-based presentation

class AccountControllerTest < ActionController::TestCase

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
    assert(@request.session[:person])
    assert_equal "Login successful", flash[:notice]
    
    assert_response(:redirect)
  end
  
  def test_admin_tester_login
    post :login, "person_login" => "test", "person_password" => "test01"
    
    assert_equal "Login successful", flash[:notice]
    assert_redirected_to :action => "list", :controller => 'proj' # we assume a root request (not necessarily the case)
    
    assert_not_nil(@request.session[:person])
    assert(@request.session[:person])
      
    admin_tester = Person.where(:login => 'test').first #  @people['admin_tester'].find
    
    assert_equal admin_tester, @request.session[:person]
    assert_response(:redirect)
  end

  def test_failed_login
    post :login, "person_login" => "test", "person_password" => "test01aaa"
    assert_equal "Login unsuccessful", flash[:notice]
    assert_nil(@request.session[:person])
  end

  def test_signup
    login # see test/helper
    post :signup, "person" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "newpassword" }
    assert(@request.session[:person])
  end

  def test_bad_signup
    login
    post :signup, "person" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "wrong" }
    assert(assigns("person").errors[:password].any?)
    assert_response(:success)
    
    post :signup, "person" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "newpassword" }
    assert(assigns("person").errors[:login].any?)
    assert_response(:success)

    post :signup, "person" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "wrong" }
    person = assigns("person")
    
    %w(first_name last_name login password).each do |col|
      assert(person.errors[col].any?)
    end
    
    assert(!assigns("person").errors[:middle_name].any?)
    assert_response(:success)
  end

  def test_invalid_login
    post :login, "person_login" => "bob", "person_password" => "not_correct"
     
    #assert_session_has_no "person"
    assert(!@request.session[:person])
    assert_equal "Login unsuccessful", flash[:notice]
    assert assigns(:login) 
  end
 
  def test_login_logoff
    test_admin_tester_login
    assert(@request.session[:person])
    get :logout
    assert(!@request.session[:person])
  end

  # TODO: delete test, reset password test
end
