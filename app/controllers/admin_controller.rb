class AdminController < ApplicationController

  # TODO: Check to see where administrator is called from
  before_filter :title

  def title
    @page_title = "Administration interface"
  end

  # this overrides the authorize? method defined in lib/login_system.rb
  def authorize?(person)
    person.is_admin?
  end

  def index
    @people = Person.find(:all, :order => "last_name")
  end

  def eol_dump
    otus = [] 
    Proj.is_eol_exportable.each do |p|
      otus += p.otus.with_content
    end
    render(:xml => Eol.eol_xml(:otus => otus), :layout => false) and return
  end

  def stats
    @stats = {}
    Dir.glob(Rails.root.to_s + '/app/models/**/*.rb').each { |file|
      m = file.gsub('/app/models/','').gsub(/\.rb/,'').gsub(/#{Rails.root.to_s}/,'')
      next if m =~ /content_type\//
      o = ActiveRecord::const_get(ActiveSupport::Inflector.camelize(m))
      @stats[ActiveSupport::Inflector.humanize(m)] = ( o.respond_to?('count') ?  o.count : 'no count')
    } 
  end

  def orphaned_images
  end

  def debug
  end 

  #def renumber_taxon_names
  #  TaxonName.renumber_all
  #  flash[:notice] = 'Taxon names have been renumbered.'
  #  redirect_to :action => :index
  #end
  #
  #def check_all_taxon_names
  #  if TaxonName.check_all
  #    flash[:notice] = 'Taxon names passed a detailed check of left/right indexing.'
  #  else
  #    flash[:notice] = 'Warning: Taxon names FAILED a detailed check of left/right indexing.'
  #  end
  #  redirect_to :action => :index
  #end

  #def check_all_quick_taxon_names
  #  if TaxonName.check_all_quick
  #    flash[:notice] = 'Taxon names passed a quick check of left/right indexing.'
  #  else
  #    flash[:notice] = 'Warning: Taxon names FAILED a quick check of left/right indexing.'
  #  end
  #  redirect_to :action => :index 
  #end

  ## I'm guessing there are no links to this action because of problems with project ownership security
  #def update_all_ref_display_names
  #  @refs = Ref.find(:all)
  #  for r in @refs
  #    r.save
  #  end
  #  flash[:notice] = 'Updated display_name field for all refs'
  #  redirect_to :action => :index 
  #end

  def people_tn
    @person = Person.find(params[:id], :include => :editable_taxon_names)
    if request.post?
      if params[:name_to_add] and params[:name_to_add][:id] and params[:name_to_add][:id] != ""
        name = TaxonName.find(params[:name_to_add][:id])
        @person.editable_taxon_names << name unless @person.editable_taxon_names.include?(name)
      end
      @person.editable_taxon_names.delete(TaxonName.find(params[:name_to_remove])) if params[:name_to_remove] 
    end
    @names_in = @person.editable_taxon_names
  end

  def reset_password
    if request.post?
      # make sure the admin can authenticate with their own password
      if session[:person].is_admin? and session[:person] == Person.authenticate(session[:person].login, params[:admin_password])
        if Person.find(params[:person_id]).update_attributes({:password => params[:new_password]})
          flash[:notice] = 'Successfully reset password'
          redirect_to :action => :index and return
        end
      end
      flash[:notice] = 'Failed to reset password'
    end          
    @people = Person.find(:all)
  end

  def new_proj
    if session[:person].creates_projects == true
      @proj = Proj.new
      @people = Person.find(:all)
      @target = 'create'
      @page_title = 'Create a new project'
    else
      flash[:notice] = "Hmm.  Clever.  You're not allowed to create projects and yet you still tried to.  We've made a note."
      logger.warn("#{session[:person].id} tried to create a project and they are not permitted to.")
      redirect_to :action => :index 
    end
  end

  def create_proj 
    @proj = Proj.new(params[:proj])

    if not params[:person][:id].empty? and (@p = Person.find(params[:person][:id]))
      if @proj.save  
        @proj.people << @p
      else 
        render :action => 'new_proj' and return
      end

      flash[:notice] = 'Project was successfully created.'
      redirect_to :action => :index
    else
      render :action => 'new_proj'
    end   
  end

  def nuke_proj
    if request.post?
      # this is a hack to avoid the whole 'owned by current project' thing
      proj = Proj.find(params[:id])
      old_proj_id = $proj_id
      $proj_id = proj.id
      if proj.destroy
        flash[:notice] = 'Project successfully deleted.'
      else
        flash[:notice] = 'Failed! Project NOT deleted.'
      end
      $proj_id = old_proj_id
    end
    @projs = Proj.find(:all)
  end    


  def destroy_image
    if o = Image.find(params[:id]) 
      if o.image_descriptions.size > 0 || Person.find($person_id).is_admin == false
        flash[:notice] = 'Hmm... what are you doing?'
        redirect_to :action => :index, :controller => :proj and return
      end
      begin
        old_id = $proj_id
        $proj_id = o.proj_id
        o.destroy 
        flash[:notice] =  "Image destroyed."         
      rescue StandardError => e
        flash[:notice] =  "#{e}"
      end
    end 
    $proj_id = old_id
    render :action => :orphaned_images
  end



end
