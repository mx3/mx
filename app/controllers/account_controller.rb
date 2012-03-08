class AccountController < ApplicationController

  # override method from LoginSystem to allow users to login
  # signup must be done by a registered user at the moment
  def protect?(action)
    if ['login', 'respond_reset_password', 'do_respond_reset_password','reset_password', 'do_reset_password'].include?(action)
      return false
    else
      return true
    end
  end

  # should make this do something else, or delete
   def index
    redirect_to :action => :login
  end

  def login
   @news = News.current_app_news('warning')
   @page_title = "Please login"
    case request.method
      when 'POST'
        if session[:person] = Person.authenticate(params[:person_login], params[:person_password])
          flash[:notice]  = "Login successful"
          session['group_ids'] = {} # used to display temporary user preferences
          redirect_back_or_default(:controller => :projs, :action => :list)
        else
          @login = params[:person_login]
          flash[:notice]  = "Login unsuccessful"
        end
    end
  end

  def signup
    case request.method
      when 'POST'
        @person = Person.new(params[:person])

        if @person.save
          session[:person] = Person.authenticate(@person.login, params[:person][:password])
          flash[:notice]  = "Signup successful"
          session['group_ids'] = {}
          redirect_back_or_default :controller => "projs", :action => "list"
        end
      when :get
        @page_title = "Signup"
        @person = Person.new
    end
  end

  def reset_password
    @page_title = "Request a password reset email"

  end

  def do_reset_password
    # First look up the person record...
    person = Person.find_by_login(params[:person_login])

    # If we find it, make a response token in the DB and send the email
    if (person)
      token = EmailResponseToken.create_token!(:person_id => person.id, :ttl => 7.days)
      AccountMailer.password_reset(person, respond_reset_password_url(token.token_key)).deliver
      notice "Password reset email sent"
      redirect_to account_login_path
    else
      error "Could not find an account with that login"
      redirect_to reset_password_path
    end
  end

  def respond_reset_password
    @page_title = "Set a new password for your account"
    @token = EmailResponseToken.find_token(params[:token_key])
    if @token

    else
      error "Could not find that email response"
      redirect_to account_login_path
    end
  end

  def do_respond_reset_password
    @token = EmailResponseToken.find_token(params[:token_key])
    if @token
      person = Person.find_by_id(@token.data[:person_id])
      person.password = params[:person_password]
      person.password_confirmation = params[:person_password_confirmation]
      if (person.save)
        notice "Updated password, please login"
        redirect_to account_login_path
      else
        person.errors.full_messages.each {|msg| error msg }
        redirect_to respond_reset_password_path(@token.token_key)
      end
    else
      error "Could not find that email response"
      redirect_to account_login_path
    end
  end

  def change_email
    @person = session[:person]
    if request.post?
      # confirm the user
      if @person == Person.authenticate(session[:person].login, params[:person_password])
        if @person.update_attribute('email', params[:person][:email])
          session[:person] = @person
          flash[:notice]  = "E-mail updated."
          @page_title = nil
          redirect_to  :controller => "projs", :action => "list"
        end
      else
        flash[:notice]  = "Couldn't confirm request."
      end
    end
  end

  def change_password
    @page_title = "Change password"
    @person = session[:person]
    if request.post?
      # confirm the old password
      if @person == Person.authenticate(session[:person].login, params[:person_password])
        if @person.update_attributes(params[:person])
          session[:person] = @person
          flash[:notice]  = "Password changed"
          @page_title = nil
          redirect_back_or_default :controller => "projs", :action => "list"
        end
      else
        flash[:notice]  = "Old password did not match"
      end
    end
  end

  def delete
    if params[:id]
      @person = Person.find(params[:id])
      if @person.destroy
        flash[:notice]  = "Delete successful"
      else
        flash[:notice]  = "WARNING! Delete failed"
      end
    end
    redirect_back_or_default :controller => "projs", :action => "list"
  end

  def logout
    @page_title = "Logout"
    session[:person] = nil
    session['group_ids'] = {}
  end

end
