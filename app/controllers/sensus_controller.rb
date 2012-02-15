class SensusController < ApplicationController

  def index
    list
    render :action => :list
  end

  def list
    @sensus = Sensu.by_proj(@proj).page(params[:page]).per(20).includes(:proj, :ref, :ontology_class, :label)
  end

  def new
    @sensu = Sensu.new
    @sensu.label = Label.find(params[:label_id]) if !params[:label_id].blank?
    @sensu.ontology_class = OntologyClass.find(params[:ontology_class_id]) if !params[:ontology_class_id].blank?
    @sensu.ref = Ref.find(params[:ref_id]) if !params[:ref_id].blank?

    respond_to do |format|
      format.html {} # default .rhtml
      format.js { }
    end
  end

  def create
    @sensu = Sensu.new(params[:sensu])
    @ontology_class = @sensu.ontology_class
    @success = @sensu.save
    if @success
      notice "Created sensu"
    end
  end

  def show
    id = params[:sensu][:id] if params[:sensu]
    id ||= params[:id]
    @sensu = Sensu.find(id)
    @show = ['default']
  end

  def edit
    id = params[:sensu][:id] if params[:sensu]
    id ||= params[:id]
    @sensu = Sensu.find(id)
  end

  def update
    @sensu = Sensu.find(params[:id])
    @sensu.update_attributes(params[:sensu])
    flash[:notice] = "Updated."
    redirect_to :action => :show, :id => @sensu
  end

  def destroy
    @sensu = Sensu.find(params[:id])
    @ontology_class = @sensu.ontology_class
    @success = @sensu.destroy
    if @success
      notice "Destroyed sensu"
    else
      notice "Failed to destroy sensu"
    end
    render :action => :create
  end
  def sort_sensus
    if params.keys.grep(/sensus_for/).empty?
      flash[:notice] = 'Error in sorting, you may have reloaded the page.'
      redirect_to(:action => :index)  and return
    end
    id_to_find = params.keys.grep(/sensus_for/).first.split("_").last  # get the key with "sensus_for" so we can have the ontology_class_id
    params[params.keys.grep(/sensus_for/).first].each_with_index do |id, index|
      Sensu.update_all(['position=?', index+1], ['id=?', id])
    end
    respond_to do |format|
      format.html {}  # shouldn't be hitting this from anywhere yet
      format.js {
        render :update do |page|
          # update the labels header, the topmost sensu being the "preferred"
          page << "if($('ontology_class_labels_for_id#{id_to_find}')) {"   # have a sensu list on the page?
            page.replace_html "ontology_class_labels_for_id#{id_to_find}", :text => labels_banner_tag(OntologyClass.find(id_to_find))
          page << "}"
        end
      }
    end
  end

  def batch_load
  end

  def batch_verify_or_create
    if params[:file].blank?
      flash[:notice] = "Provide a file."
      redirect_to :action => :batch_load and return
    end

    @file =  params[:file]
    md5 = Digest::MD5.hexdigest(@file.read)

    @file.rewind

    begin
      if params[:verify]
        @result = Ontology::OntologyMethods.sensus_from_file(:file => @file, :proj_id => @proj.id)
        session["#{$person_id}_sensu_ld_md5_#{md5}"] = md5 # nothing has been thrown, verify this file in the session
        @operation = "verifying"
        @file.rewind
        render :action => :batch_verify
      elsif params[:create]
        if session["#{$person_id}_sensu_ld_md5_#{md5}"] == md5 # then this person verified the this file
          @result = Ontology::OntologyMethods.persist_sensus_from_file(
                                                   :sensus_from_file_result => Ontology::OntologyMethods.sensus_from_file(:file => @file, :proj_id => @proj.id),
                                                   :proj_id => @proj.id,
                                                   :person_id => $person_id,
                                                   :written_by_ref_id => ((params[:ref] && !params[:ref][:id].blank?) ? params[:ref][:id] : nil)
                                                  )
          @operation = "created"
          @file.rewind
          render :action => :batch_verify
        else
          raise "This file has not yet been verified, please do so first."
        end
      end
    rescue StandardError => e
     flash[:notice] = "Failed to parse: #{e}"
     redirect_to :action => :batch_load and return
    end
  end

  def auto_complete_for_sensus
    @sensus = Sensu.auto_complete_search_result(params.merge!(:proj_id => @proj.id))
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @sensus, :method => params[:method])
  end

  protected
end
