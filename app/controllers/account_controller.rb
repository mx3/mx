class AccountController < ApplicationController

  # override method from LoginSystem to allow users to login
  # signup must be done by a registerd user at the moment
  def protect?(action)
    if ['login'].include?(action)
      return false
    else
      return true
    end
  end

  def login
   @news = News.current_app_news('warning')  
   @page_title = "Please login"
    
    case request.method
      
      when 'POST'
        if session[:person] = Person.authenticate(params[:person_login], params[:person_password])
          flash[:notice]  = "Login successful"
          session['group_ids'] = {} # used to display temporary user preferences
          redirect_back_or_default(:controller => :proj, :action => :list)
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
          redirect_back_or_default :controller => "proj", :action => "list"          
        end
      when :get
        @page_title = "Signup"
        @person = Person.new
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
          redirect_to  :controller => "proj", :action => "list"
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
          redirect_back_or_default :controller => "proj", :action => "list"
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
    redirect_back_or_default :controller => "proj", :action => "list"
  end  
    
  def logout
    @page_title = "Logout"
    session[:person] = nil
    session['group_ids'] = {} 
  end
  
end
