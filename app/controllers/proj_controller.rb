class ProjController < ApplicationController
  # @proj is set by a 'before_filter'. Project membership is checked in a filter as well
  # see AdminController for creating new projects 

  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

  def index
    list
    render :action => 'list'
  end

  def list
    @page_title = "Choose a project"

    person = Person.find($person_id)
    @all_projs = Proj.find(:all, :order => 'name')
    @persons_projs = person.projs.collect{|p| p.id}
    @is_admin = person.is_admin
    @news = News.current_app_news
  end

  def show
  end

  def edit
    @proj = Proj.find(params[:id])
    @people = Person.find(:all, :order => 'login')
    @target = 'update' # GET RID OF THIS!
    _set_pub_controllers 
  end

  def _set_pub_controllers
    @pub_controllers = []
    @pub_controllers = Dir.glob(File.join("#{Rails.root.to_s}/app/controllers/public", "*_controller.rb")).collect {|f| File.basename(f, "_controller.rb")}
    @pub_controllers.push "site/#{@proj.unix_name}/home" if Dir.glob(File.join("#{Rails.root.to_s}/app/controllers/public/site/#{@proj.unix_name}", "*_controller.rb")).collect {|f| File.basename(f, "_controller.rb")}.size > 0
  end

  def update
    @proj = Proj.find(params['id'])

    if @proj.update_attributes(params['proj'].merge(
                                                    {'hidden_tabs' => make_ar('hidden_tabs'), 'public_controllers' => make_ar('public_controllers')}))
      @proj.people.clear
      @people = Person.find(:all)
      for person in @people                       # if it is saved we can add the people-projects links
        if (params[:people][person.login])        # if a login is in params it is because the user checked that box
          @proj.people<<(person)                  # so we insert the person in the collection using the '<<' method
        end
      end
      session[:proj] = nil # forces the project stored in the session to be freshly loaded next time
      flash[:notice] = 'Proj was successfully updated.'
      redirect_to :action => 'show', :id => @proj.id
    else
      @people = Person.find(:all)
      @target = 'update'
      _set_pub_controllers 
      render :action => 'edit'

    end
  end

  def destroy
    # can only be destroyed by creator or admin which is set on logon
    p = Proj.find(params[:id])

    if p && p.nuke($person_id)
      flash[:notice] = "Destroyed the project."
    else
      flash[:notice] = "Failed to destroy the project, contact an adminstrator."
    end

    redirect_to :controller => '/proj', :action => 'list'
  end

  def summary
    @klass = "Proj"
    @proj = Proj.find(params[:id])
  end

  def my_data
    if request.post?
      @foo = @proj.table_csv_string(:klass => params[:klass].constantize)
      send_data @foo, :type => "text/plain", :filename=> "project_#{@proj.id}_#{params[:klass]}_#{Time.now.day}_#{Time.now.month}_#{Time.now.year}.csv", :disposition => 'attachment' and return
    end
  end

  def eol_dump
    render(:xml => Eol.eol_xml(:otus => @proj.otus.with_taxon_name_populated.with_content), :layout => false) and return
  end

  def generate_ipt_records
    @proj = Proj.find(params['id'])
    Ipt::Batch::serialize_projects(:proj_ids => [@proj.id])

    redirect_to :action => :show, :id => @proj.id
  end

  private

  def make_ar(thing)
    ar = []
    params[thing].each_pair {|k,v| ar << k } if params[thing]
    ar
  end

end
