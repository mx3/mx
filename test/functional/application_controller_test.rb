require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'application_controller'


class ApplicationController; def rescue_action(e) raise e end; end 
class ApplicationControllerTest < ActionController::TestCase

  include ActionDispatch::Routing::UrlFor

  def setup
    # doesn't really matter what controller we have for some basic routes testing.
    @controller = AccountController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
  end

  def teardown
    session = nil
  end

  def test_route_1
    # '/public/ref/+' - should return 404
    opts = {"anything"=> ["public", "ref", "+"],
      "action"=>"index",
      "unresolvable"=>"true",
      "controller"=>"application"}
    assert_recognizes(opts, 'public/ref/+')
  end

  def test_route_2
    opts = {
      :controller => 'public/ref'
    }
    assert_generates('/public/ref', opts)
    assert_recognizes opts.update({:action => 'index'}), 'public/ref'
  end
    
  def test_route_3
    opts = {:action => "index", :controller => "public/ref", :proj_id => "12"}
    assert_recognizes opts , 'projects/12/public/ref'
    assert_routing 'projects/12/public/ref', opts
  end

end
