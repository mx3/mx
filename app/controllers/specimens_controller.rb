# TODO mx3: resolve this -  require 'material_accessions'

class SpecimensController < ApplicationController

  def test
  end

  def index
    list
    render :action => :list
  end

  def list
    @specimens = Specimen.by_proj(@proj)
      .page(params[:page])
      .per(20)
      .includes(:ce, :repository, {:most_recent_determination => [:creator, {:otu => {:taxon_name => :parent}}]},{:identifiers => :namespace},:creator, :updator)
      .order('identifiers.cached_display_name, specimens.id')
    @inc_actions = true # the specimen table is used various places
  end

  def search_by_identifier
    if params[:search].blank? or params[:search][:string].blank?
      flash[:notice] = "No search string provided to search by identifier."
      redirect_to :action => 'list' and return
    end

    @specimens = Specimen.find_by_identifiers(:string => params[:search][:string], :project => @proj)

    @target = 'all'
    render :action => 'list'
  end

  def list_all
    @specimens = @proj.specimens
    @target = 'all'
    render :action => 'list'
  end

  def list_by_current_user
    @specimens = @proj.specimens(:include => [:identifiers]).created_by(session[:person].id)
    @target = 'all'
    render :action => 'list'
  end

  def list_by_creator
    @specimens = @proj.specimens. Specimen.by_identifier(@proj.id)
    @target = 'all'
    render :action => 'list'
  end

  def show
    id = params[:specimen][:id] if params[:specimen] # for ajax picker use
    id ||= params[:id]
    @specimen = Specimen.find(id, :include => [:identifiers])
    @dets = SpecimenDetermination.find_all_by_specimen_id(params[:id])
    @show = ['default']
  end

  def show_seqs
    id = params[:specimen][:id] if params[:specimen] # for ajax picker use
    id ||= params[:id]
    @specimen = Specimen.find(id)
    render :action => :show
  end

  def params_for_new_specimen
    #  @specimen = Specimen.new  <- don't put this here! (for cloning purposes)
    @type_specimen = TypeSpecimen.new
    @identifier = Identifier.new(params[:identifier])
    @specimen.ce_id = params[:start_with_ce_id] if !params[:start_with_ce_id].blank?

    if params[:lock_ce]
      @lock_ce = true
      session[:default_ce_id] = params[:specimen][:ce_id]
    else
      session[:default_ce_id] = nil
    end

    if @proj.default_specimen_identifier_namespace && @identifier.namespace.blank?
      @identifier.namespace = @proj.default_specimen_identifier_namespace
    end

    @specimen.repository_id = session[:person].pref_default_repository_id if @specimen.repository_id.blank?
    @type_assignments = @specimen.type_assignments
  end

  def new
    @specimen = Specimen.new(params[:specimen])
    params_for_new_specimen
    @target = 'edit'
  end

  def create
    @specimen = Specimen.new(params[:specimen])
    begin
      Specimen.transaction do
        @specimen.save!
        if @identifier = Identifier.create_new(params[:identifier].merge(:object => @specimen))
          @identifier.save!
        end
        if @type_specimen = TypeSpecimen.create_new(params[:type_specimen].merge(:specimen_id => @specimen.id))
          @type_specimen.save!
        end
        unless (params[:specimen_determination][:otu_id].blank?) and (params[:specimen_determination][:name].blank?)
          @specimen_determination = SpecimenDetermination.new(params[:specimen_determination])
          @specimen.specimen_determinations << @specimen_determination
        end
      end

    rescue ActiveRecord::RecordInvalid => e
      flash[:notice] = e.message
      respond_to do |format|
        format.html {
          params_for_new_specimen
          render(:action => :new) and return
        }
        format.js {
          render :update do |page|
          page.replace_html :notice, flash[:notice]
          flash.discard
          end and return
        }
      end
    end

    respond_to do |format|
      format.html {
        case params[:commit]
        when 'Create'
          flash[:notice] = "Specimen (mxID #{@specimen.id}) was successfully created."
          redirect_to :action => 'show', :id => @specimen and return
        when 'Create and next'
          flash[:notice] = "Specimen (mxID #{@specimen.id}) was successfully created."
          redirect_to :action => :new and return
        when  'Create, clone and next'
          flash[:notice] = "Specimen (mxID #{@specimen.id}) was successfully created, this is the new clone."
          params_for_new_specimen
          render :action => :new and return
        when  'Create, clone, increment identifier'
          flash[:notice] = "Specimen (mxID #{@specimen.id}) was successfully created, this is the new clone with incremented identifier."
          params_for_new_specimen
          @identifier.identifier =  params[:identifier][:identifier].to_i + 1
          render :action => :new and return
        else
          redirect_to :action => :list
        end
      }

      format.js {
        flash[:notice] = "Successfully created specimen with mx id #{@specimen.id}."
        params_for_new_specimen

        render :update do |page|
          page.insert_html :top, :specimens, :partial => 's', :object => @specimen
          if params[:clear_form]
            page[:specimen_form].reset
          end

          page.replace_html :notice, flash[:notice]
          page[:specimen_total].replace_html "<i>incremented post load.</i>"
          flash.discard
        end
      }
    end
  end

  def quick_create
    begin
      Specimen.transaction do
        @specimen = Specimen.new(params[:specimen])
        @ce = Ce.new(params[:ce])
        @ce.save
        @specimen.ce = @ce
        @specimen.save!

        if @identifier = Identifier.create_new(params[:identifier].merge(:object => @specimen))
          @identifier.save!
        end

        if !(params[:specimen_determination][:otu_id].blank?) && (params[:specimen_determination][:name].blank?)
          @specimen_determination = SpecimenDetermination.new(params[:specimen_determination])
          @specimen.specimen_determinations << @specimen_determination
        end

        @specimen.save!

        if @specimen_determination.nil?
          flash[:notice] = "Specimen created with no determination!"
          redirect_to(:action => :edit, :id => @specimen) and return
        end

        case params[:commit]
        when 'Create'
          flash[:notice] = "Specimen (mxID #{@specimen.id}) was successfully created."
          redirect_to :action => :show, :id => @specimen and return
        when 'Create and next'
          flash[:notice] = "Specimen (mxID #{@specimen.id}) was successfully created."
          params_for_new_specimen
          redirect_to :action => :quick_new and return
        when  'Create, clone and next'
          flash[:notice] = "Specimen (mxID #{@specimen.id}) was successfully created, this is the new clone."
          params_for_new_specimen
          render :action => :quick_new and return
        else
          redirect_to :action => :list
        end
      end

    rescue Exception => e
      flash[:notice] = "Something went wrong. #{e}"
      redirect_to :action => :quick_new
    end
  end

  def quick_new
    @specimen = Specimen.new
    params_for_new_specimen
  end

  def edit
    @specimen = Specimen.find(params[:id], :include => [:preparation, :identifiers, {:specimen_determinations => {:otu => :taxon_name}}, :type_specimens])
    @type_assignments = @specimen.type_specimens
  end

  def update
    @specimen = Specimen.find(params[:id])

    begin
      Specimen.transaction do
        @specimen.update_attributes(params[:specimen])

        if @identifier = Identifier.create_new(params[:identifier].merge(:object => @specimen))
          @identifier.save!
        end
        if @type_specimen = TypeSpecimen.create_new(params[:type_specimen].merge(:specimen_id => @specimen.id))
          @type_specimen.save!
        end
        unless (params[:specimen_determination][:otu_id].blank?) && (params[:specimen_determination][:name].blank?)
          @specimen_determination = SpecimenDetermination.new(params[:specimen_determination])
          @specimen.specimen_determinations << @specimen_determination
        end
      end

    rescue ActiveRecord::RecordInvalid => e
      flash[:notice] = "Failed to update the record: #{e.message}."
      redirect_to :back and return
    end

    flash[:notice] = 'Updated the record.'
    redirect_to :action => :show, :id => @specimen
  end

  def destroy
    Specimen.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def destroy_type_assignment
  end

  ## ! these two need post protection
  def destroy_identifier
    Identifier.find(params[:id]).destroy
    redirect_to :back
  end

  def destroy_determination
    SpecimenDetermination.find(params[:id]).destroy
    redirect_to :back
  end

  def auto_complete_for_specimen
    value = params[:term]
    method = params[:method]
    @specimens = Specimen.find_for_auto_complete(value)
    data = @specimens.collect do |specimen|
      {:id=> specimen.id,
       :label=> specimen.display_name,
       :response_values=> {
          'specimen[id]' => specimen.id
          # :hidden_field_class_name => @tag_id_str # not Sure wht this is for, probably delete.
       },
       :label_html => specimen.display_name(:type => :for_select_list)
      }
    end
    render :json => data
  end

  def clone
    s = Specimen.find(params[:id])
    @specimen = s.make_clone
    flash[:notice] = "Editing newly cloned specimen."
    redirect_to :action => :edit, :id => @specimen
  end

  def batch_load
  end

  def batch_verify_or_create
    if params[:file].blank?
      flash[:notice] = "Provide a file."
      redirect_to :action => :batch_load and return
    end

    @file =  params[:file].read
    md5 = Digest::MD5.hexdigest(@file)

    begin
      if params[:verify]
        @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
        session["#{$person_id}_spec_ld_md5_#{md5}"] = md5 # nothing has been thrown, verify this file in the session
        @operation = "verifying"
        render :action => :batch_verify
      elsif params[:create]
        if session["#{$person_id}_spec_ld_md5_#{md5}"] == md5 # then this person verified the this file
          @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id, :save => true)
          @operation = "created"
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

  # tests/hacking
  def group
    render :action => 'group/index'
  end

  def identifier_search
    @specimens = Specimen.find_by_identifiers(:project => @proj, :string => params[:string])
    respond_to do |format|
      format.js {
        render :update do |page|
        if @specimens.length > 0
          page.replace_html :result, :partial => '/specimen/group/result', :locals => {:specimens => @specimens}
        else
          page.replace_html :result, content_tag(:em, 'No matches found.')
        end
        flash.discard
        end and return
      }
    end
  end

  def group_result_update
    respond_to do |format|
      format.js {
        render :update do |page|

        if @specimens = Specimen.group_update(params.merge(:project => @proj))
          page.replace_html :result, :partial => '/specimen/group/summary', :locals => {:specimens => @specimens}
        else
          page.replace_html :details, content_tag(:div, 'Update error, please check form details.', :style => 'color:red;font-weight:777;')
        end
        flash.discard
        end and return
      }
    end
  end

  # TODO:remove this test
  def accordion
    @specimen = Specimen.find(:first, :conditions => "proj_id = #{@proj.id}")
  end

  private

end
