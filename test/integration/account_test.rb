require "test_helper"

class AccountTest < ActionController::IntegrationTest
  test "reset we respond to a valid response and set a good password and authenticate works on new password" do
    person = Person.make!
    post reset_password_path, :person_login => person.login
    assert_redirected_to account_login_path
    token  =  EmailResponseToken.last

    get respond_reset_password_path(token.token_key)
    assert_response :success

    post respond_reset_password_path(token.token_key), {:person_password => "12345678", :person_password_confirmation => "12345678" }
    assert_redirected_to account_login_path

    post account_login_path, :person_login => person.login, :person_password => "12345678"
    assert flash[:error].blank?
  end

  test "reset we responsd to valid response with invalid password" do
    person = Person.make!
    post reset_password_path, :person_login => person.login
    assert_redirected_to account_login_path
    token  =  EmailResponseToken.last

    get respond_reset_password_path(token.token_key)
    assert_response :success

    post respond_reset_password_path(token.token_key), {:person_password => "1", :person_password_confirmation => "1" }
    assert_redirected_to respond_reset_password_path(token.token_key)
    assert flash[:error]
  end

  test "reset we respond with an invalid token" do
    person = Person.make!
    post reset_password_path, :person_login => person.login
    assert_redirected_to account_login_path
    token  =  EmailResponseToken.last

    get respond_reset_password_path(token.token_key + "foo")
    assert_redirected_to account_login_path
    assert flash[:error]
  end
end
