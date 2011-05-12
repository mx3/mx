require "#{File.dirname(__FILE__)}/../test_helper"

class RefAndAuthorsTest < ActionController::IntegrationTest
  # including all your fixtures ensures that the test data gets reloaded each run
  fixtures :people, :people_projs, :projs, :refs, :serials, :languages
   
  def setup
    post_via_redirect "/account/login", 
                  :person_login => 'tester',
                  :person_password => 'test02'
                
    assert_response :success
    assert_equal  5, session[:person].id
    assert_template "proj/list"
  end
  
  def dont_test_display_name_rendering # not working in 2.2.2 for some reason
    get "/projects/1/ref/"
    assert_response :success
    assert_template "ref/list"
    
    get "/projects/1/ref/new" # can't do @opts
    assert_response :success
    assert_template "new"

    s= Serial.new(:name => 'Journal of Stuff and Things')
    s.save
    
    post_via_redirect '/projects/1/ref/create',
          :auth => {:last_name => "Foo", :first_name => "Bar", :auth_is => 'author'},
          :ref => {:year => '2000', :title => "A title", :serial_id => s.id, :pg_start => 1, :pg_end => 5, :volume => 10}
    assert_response :success
    assert_template "edit"   
    
    r = Ref.find(:first, :order => 'id DESC')
    assert_equal 1, r.authors.size
    assert_equal 1, r.auths.size
    assert_equal 0, r.editors.size
    
    assert_equal 'Foo, B. 2000. A title. Journal of Stuff and Things 10:1-5.', r.display_name
    assert_equal 'Foo 2000', r.short_citation

    post_via_redirect '/projects/1/ref/update',
         :id => r.id, 
         :authors => '', # old authors
         :auth => {:last_name => "Blorf", :first_name => "Smorf", :auth_is => 'author'}
    assert_response :success
    assert_template "edit"     
        
    r1 = Ref.find(:first, :order => 'id DESC')     
    assert_equal 'Foo, B., and S. Blorf. 2000. A title. Journal of Stuff and Things 10:1-5.', r1.display_name
         
  end
end
