require "#{File.dirname(__FILE__)}/../test_helper"

class SerialMatchingTest < ActionController::IntegrationTest
  # including all your fixtures ensures that the test data gets reloaded each run
  fixtures :people, :people_projs, :projs, :serials
   
  def setup
   
  end
  
  def dont_test_serial_matching
    request_via_redirect :post, "/account/login", {:person_login => 'tester',:person_password => 'test02'}
                
    assert_response :success
    assert_equal  5, session[:person].id
    assert_template "proj/list"


    s1 = Serial.create!(:name => 'Journal of Stuff and Things')
    s2 = Serial.create!(:name => 'J. BS Sc.')
    
    get "/projects/1/serial/match"
    assert_response :success
    assert_template "serial/match"

    # the following doesn't work, chokes on params[:temp_file].read ... missing an include?!
    # post_via_redirect '/projects/1/serial/match', :temp_file => fixture_file_upload('test_files/serial_upload_test.txt')
    # assert_response :success
    # assert_template "serial/match"  
    # assert_equal 3, @file_serials.size
  end



end

