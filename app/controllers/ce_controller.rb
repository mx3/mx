class CeController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

  auto_complete_for :ce, :collectors, :limit => 100
  auto_complete_for :ce, :locality, :limit => 100
  auto_complete_for :ce, :mthd, :limit => 100
  auto_complete_for :ce, :verbatim_method, :limit => 100

  auto_complete_for :ce, :macro_habitat, :limit => 100
  auto_complete_for :ce, :micro_habitat, :limit => 100

  def index
    list
    render :action => 'list'
  end

  def list_params
    @ce_pages, @ces = paginate :ce, :per_page => 25, :conditions => "(proj_id = #{@proj.id})", :order => "updated_on DESC"
  end
  
  def list
    list_params
     if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def list_by_scope
    if params[:arg]
      @ces = @proj.ces.send(params[:scope],params[:arg])
    else
      @ces = @proj.ces.send(params[:scope])
    end 
    @list_title = "Collecting events #{params[:scope].humanize.downcase}" 
    render :action => :list_simple
  end

  def _show_params
    id = params[:ce][:id] if params[:ce] # for autocomplete/ajax picker use (must come first!)
    id ||= params[:id]
   
    @ce = Ce.find(id)
  end
  
  def show
    _show_params
    @no_right_col = false
    @show = ['default']
  end

  def show_material
    _show_params
    @lots = @ce.lots.limit(500).include_identifiers.include_has_manys.include_tags
    @specimens = @ce.specimens.limit(500).include_identifiers.include_has_manys.include_tags
    @total_specimens = @ce.specimens.count
    @total_lots = @ce.lots.count
    @total_ipt_records = @ce.ipt_records.count 
    @no_right_col = true
    render :action => 'show'
  end
  
  def new
    @ce = Ce.new
  end

  def new_fast
     @target = 'fast'
     @ce = Ce.new
     render :action => 'new_fast'
  end

  def create
    @ce = Ce.new(params[:ce])
    if @ce.save
      flash[:notice] = "Collecting event successfully created, ID is #{@ce.id}."
      if params['target'] == 'fast'
        case params[:commit]
        when 'Create and next'
          redirect_to :action => :new_fast and return
        when 'Create and new specimen'
          redirect_to(:action => :new, :controller => :specimen, 'specimen[ce_id]' => @ce.id)  and return
        end
      else
        case params[:commit]
        when 'Create and next'
          flash[:notice] << " This is the new record."
          redirect_to :action => :new and return
        when 'Create, clone and next'
          flash[:notice] << ' This is the clone.'
          render :action => :new and return
        when 'Create and new specimen' 
          redirect_to(:action => :new, :controller => :specimen, 'specimen[ce_id]' => @ce.id) and return
        else
          flash[:notice] << " This is the new record."
          redirect_to :action => :show, :id => @ce.id and return
        end
        redirect_to :action => :show, :id => @ce.id and return
      end
    else
      flash[:notice] = 'Collecting event not saved!'
      render :action => :new and return
    end
  end

  def edit
    @ce = Ce.find(params[:id])
  end

  def update
    @ce = Ce.find(params[:id])
    if @ce.update_attributes(params[:ce])
      flash[:notice] = 'Collecting event was successfully updated.'

      if params[:update_and_next]
        @id = Ce.find(:first, :conditions => ["proj_id = #{@proj.id} AND id > ?", @ce.id], :order => 'id ASC')
          if @id
            redirect_to(:action => :edit, :id => @id) 
          else
            flash[:notice] = 'Last record reached.'
            redirect_to(:action => :list)
          end
      else
        redirect_to :action => :show, :id => @ce
      end
    else
      flash[:notice] = 'Error updating collecting event.'
      render :action => :edit
    end
  end

  def destroy
    Ce.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def clone
    ce = Ce.find(params[:id])
    begin
      Ce.transaction do
        @ce = ce.clone
        @ce.locality ? @ce.locality += " [CLONE OF #{ce.id}]\n" : @ce.locality = "[CLONE OF #{ce.id}]\n"
        @ce.save
      end
    rescue
      flash[:notice] = "Failed to clone the Ce, contact an admin."
      redirect_to :action => :show, :id => ce.id and return
    end
    flash[:notice] = "Cloned! From #{ce.id}." 
    render :action => :new
  end

  def auto_complete_for_ce
    @tag_id_str = params[:tag_id]
    
    value = params[@tag_id_str.to_sym]

    @ces = Ce.find_for_auto_complete(value)
    render :inline => "<%= auto_complete_result_with_ids(@ces,
      'format_obj_for_auto_complete', @tag_id_str) %>"
  end
 
  # label related functions

  def labels
    @labels = @proj.ces.to_print
  end

  def labels_clear_to_zero
    for l in  @proj.ces.to_print 
       l.num_to_print = nil
       l.save
     end
      
    redirect_to :action => 'labels'
  end

  def labels_print_preview
    # Need to make this smarter to count lines, not labels, at that point it should pretty much be set to render
    # perfectly

    redirect_to :action => :labels and return if params[:lbl].blank?
    
    # This will change to map more cleverly, its a hack for Jonathon

    @css = params[:lbl][:type].to_s
    @lines_per_col = params[:lbl][:lines_per_col].to_i
    @columns_max = params[:lbl][:columns_max].to_i
    @labels = Ce.find(:all, :conditions => ["ces.num_to_print > 0 and proj_id = ?", @proj.id ])

    render :layout => false
  end

  def batch_load
  end

  def batch_verify
     if params[:temp_file][:file].blank?
       flash[:notice] = "Choose a text file with your labels in it before verifying!"
       redirect_to(:action => :batch_load) and return  
     end
   
    # read the contents of the uploaded file
    @ces = Ce.from_text(params[:temp_file][:file].read)
  end

  def batch_create
    @count = 0
    @existing_labels = []
    begin
      Ce.transaction do
        for ce in params[:ce].keys
          if params[:check][ce]
            if @exists = Ce.find(:first, :conditions => {:verbatim_label_md5 => Ce.generate_md5(params[:ce][ce]), :proj_id => @proj.id})
              @existing_labels.push(@exists)
            else
              @c = Ce.new(:verbatim_label => params[:ce][ce], :print_label => params[:ce][ce])
              @c.save
              @count += 1
            end
          end
        end
      end

    rescue ActiveRecord::RecordNotSaved => e
      flash[:notice] = "Something went wrong (at label #{@count} :: #{@c.errors.to_yaml}): #{e}"
      redirect_to :action => :batch_load and return
    end
     
    flash[:notice] = "Successfully added #{@count} labels. Matched with existing data, and did NOT add #{@existing_labels.size} labels." 
    redirect_to :action => :batch_load
  end

  def new_from_gmap
  end
 
  def new_from_geocoder
    @ce = Ce.new_from_geocoder(params)
    render :action => :new
  end

 def find_similar
    if !params[:arg].blank?
      @ces = @proj.ces.send(params[:scope],params[:arg]).excluding_id(params[:id])
    else
      @ces = [] # @proj.ces.send(params[:scope])
    end 
    respond_to do |format|
    format.html {
      redirect_to :action => :index} 
    format.js {
      render :update do |page|
        @ces =  @ces.collect{|c| content_tag(:div, link_to(c.display_name, :action => :show, :id => c.id)) }.join
        page.replace_html :similar_ces, :text => (@ces.length > 0 ?
           content_tag(:div, content_tag(:p, "similar to #{params[:scope]}") + @ces, :style => 'padding:2px') :
           content_tag(:em, 'none'))
      end and return
    }
    end
  end

  def create_from_gmap # in development
    ce = Ce.new(params[:m])
    if ce.save
        res={:success=>true,:content=>"<div><strong>ID: </strong>#{ce.id}</div><div><strong>Verbatim Label: </strong>#{ce.verbatim_label}</div><div><strong>Notes: </strong>#{ce.notes}</div><div><strong>Lat: </strong>#{ce.latitude}</div><div><strong>Long: </strong>#{ce.longitude}</div>"}
      else
        res={:success=>false,:content=>"Could not save the marker!"}
      end
    render :text=>res.to_json
  end
 
  def batch_geocode
    @ces = @proj.ces.with_verbatim_label.mappable[15..20] 
  end 

end
