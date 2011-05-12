class PersonController < ApplicationController

 verify :method => :post, :only => [ :update ],
    :redirect_to => { :action => :list }


  def index
    redirect_to :action => :preferences
  end

  def preferences
    @person = Person.find($person_id) # the logged in version, for sekurity
  end

  def update
    @person = Person.find($person_id)

    if @person.update_preferences(params) # can't just dump params[:person] in there because of password setting filters
      flash[:notice] = "Saved."
    else
      flash[:notice] = "Problem updating preferences"
    end
    redirect_to :action => :preferences
  end

end
