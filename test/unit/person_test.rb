require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class PersonTest < ActiveSupport::TestCase

  fixtures :people

  def setup
    set_before_filter_vars # sets $person_id = 1, $proj_id = 1
    @proj = Proj.find($proj_id)
  end

  def test_password_must_be_8_long
    @p = make_new_user
    @p.password = @p.password_confirmation = "too_sml" 
    assert !@p.save
    assert @p.errors.invalid?('password')
  end

  def test_updating_preferences_does_not_reset_password
    @p = Person.new(:first_name => "Foo", :password_confirmation => "12345678", :password => "12345678", :last_name => "Bar", :email => "foo@bar.com", :login => "fbar", :email => "foo@bar.com")
    assert @p.save

    foo = @p.password
    @p.update_attributes(:pref_mx_display_width => 2, :pref_mx_display_height => 4)
    @p.reload
    
    assert_equal foo, @p.password
  end 

  def make_new_user
    Person.new(:login => "okbob", :first_name => "bob", :last_name => "bob",
               :password =>  "bobs_secure_password", :password_confirmation =>  "bobs_secure_password", :email => 'l33t@dudes.com')
  end
    
  def test_auth
    bob = make_new_user
    bob.save!
    assert_equal bob, Person.authenticate("okbob", "bobs_secure_password")    
    assert_equal nil, Person.authenticate("nonbob", "bobs_secure_password")
    assert_equal nil, Person.authenticate("okbob", "test")
  end


  def test_passwordchange
    bob = make_new_user
    bob.save!
    bob.password = bob.password_confirmation = "nonbobpasswd"
    bob.save!
    
    assert_equal bob, Person.authenticate("okbob", "nonbobpasswd")
    assert_nil  Person.authenticate("okbob", "longtest")
    
    bob.password = bob.password_confirmation = "longtest"
    bob.save!
    
    assert_equal bob, Person.authenticate("okbob", "longtest")
    assert_nil   Person.authenticate("okbob", "nonbobpasswd")        
  end
  
  def test_disallowed_passwords
    u = make_new_user
    u.login = "nonbob"

    u.password = u.password_confirmation = "tiny"
    assert !u.save
    assert u.errors.invalid?('password')

    u.password = u.password_confirmation = "hugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehuge"
    assert !u.save     
    assert u.errors.invalid?('password')
        
    u.password = u.password_confirmation = ""
    assert !u.save    
    assert u.errors.invalid?('password')
        
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save     
    assert u.errors.empty?
        
  end
  
  def test_bad_logins

    u = make_new_user
    u.password = u.password_confirmation = "bobs_secure_password"
    u.first_name = u.last_name = "bob"

    u.login = "tny"
    assert !u.save     
    assert u.errors.invalid?('login')
    
    u.login = "hugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhug"
    assert !u.save     
    assert u.errors.invalid?('login')

    u.login = ""
    assert !u.save
    assert u.errors.invalid?('login')

    u.login = "okbob"
    assert u.save
    assert u.errors.empty?
  
  end

  def test_collision
    u = make_new_user
    u.save!
    u2 = make_new_user 
    u2.login = u.login
    assert !u.save
  end

  def test_create
    u = make_new_user
    u.login      = "nonexistingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
      
    assert u.save  
    
  end
  
  def test_sha1
    u = make_new_user
    u.login      = "nonexistingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
        
    assert_equal 'f08571e915afb1e4dcefbf3071a6eaa19b88400f', u.password
    
  end

  
end




