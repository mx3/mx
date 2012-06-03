class OtuGroupsController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list
    @otu_groups = @proj.otu_groups
  end

  def show
    id = params[:otu_group][:id] if params[:otu_group]
    id ||= params[:id]
    @otu_group = OtuGroup.find(id, :include => [:otus])
    @otus_in = @otu_group.otu_groups_otus(:include => :otus)
    @show = ['default']
  end

  def show_material
    @otu_group = OtuGroup.find(params[:id], :include => [:otus])
    @specimens = @otu_group.otus.inject([]){|sum, o| sum + o.specimens}
    @lots = @otu_group.otus.inject([]){|sum, o| sum + o.lots}
    @markers = @otu_group.gmaps_markers
    @no_right_col = true
    render :action => 'show'
  end

  def show_images
   @otu_group = OtuGroup.find(params[:id], :include => [:otus])
   @descriptions = @otu_group.otus.inject([]){|sum, o| sum + o.image_descriptions(@proj.id)}.uniq
   @no_right_col = true
   render :action => 'show'
  end

  def show_collecting_events
   @otu_group = OtuGroup.find(params[:id], :include => [:otus])
   @collecting_events = @otu_group.collecting_events
   @no_right_col = true
   render :action => 'show'
  end

  def show_content_grid
    id = params[:otu_group][:id] if params[:otu_group]
    id ||= params[:id]
    @otu_group = OtuGroup.find(id, :include => :otus)
    @templates = @proj.content_templates

    respond_to do |wants|
      wants.html {
        @no_right_col = true
        render :action => 'show'
      }
      wants.js
    end
  end

  def show_descriptions
    id = params[:otu_group][:id] if params[:otu_group]
    id ||= params[:id]
    @otu_group = OtuGroup.find(id)
    @templates = @proj.content_templates

    respond_to do |wants|
      wants.html {
        @no_right_col = true
        render :action => 'show'
      }
      wants.js
    end
  end

  def show_verbose_specimens_examined
    id = params[:otu_group][:id] if params[:otu_group]
    id ||= params[:id]
    @otu_group = OtuGroup.find(id, :include => :otus)
    @no_right_col = true
    render :action => 'show'
  end

  def show_extract_grid
    id = params[:otu_group][:id] if params[:otu_group]
    id ||= params[:id]
    @otu_group = OtuGroup.find(id, :include => :otus)
    @no_right_col = true
    render :action => 'show'
  end

  def show_extract_grid_by_extract
    id = params[:otu_group][:id] if params[:otu_group]
    id ||= params[:id]
    @otu_group = OtuGroup.find(id, :include => :otus)
    @no_right_col = true
    render :action => 'show'
  end

  def show_extract_grid_by_gene
    id = params[:otu_group][:id] if params[:otu_group]
    id ||= params[:id]
    @otu_group = OtuGroup.find(id, :include => :otus)
    @genes = @otu_group.genes
    @extracts = @otu_group.extracts
    @no_right_col = true
    render :action => 'show'
  end

  def new
    @otu_group = OtuGroup.new
  end

  def create
    @otu_group = OtuGroup.new(params[:otu_group])

    if @otu_group.save
      flash[:notice] = 'OtuGroup was successfully created.'
      redirect_to :action => 'list'
    else
      redirect_to :action => 'new'
    end
  end

  def edit
    @otu_group = OtuGroup.find(params[:id])
  end

  def update
    @otu_group = OtuGroup.find(params[:otu_group][:id])
    if @otu_group.update_attributes(params['otu_group'])
      flash[:notice] = 'OtuGroup was successfully updated.'
      redirect_to :action => 'show', :id => @otu_group.id
    else
      render :action => 'edit'
    end
  end

  def destroy
    OtuGroup.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def add_otu
    if @otu_group = OtuGroup.find(params[:id])
      if o = Otu.find(params[:otu][:id])
        if @otu_group.add_otu(Otu.find(params[:otu][:id])) # !! NOT << , previous membership is checked in .add_otu
          notice 'Added an OTU.'
        else
          error "Problem adding OTU, perhaps its in the list already?"
        end
      else
        error "Incorrect parameters to add OTU."
      end
    else
      error "Can't find that OTU."
    end
    redirect_to :action => 'show', :id => @otu_group.id
  end

  def remove_otu
    @otu_group = OtuGroup.find(params[:id])
    @otu_group.remove_otu(Otu.find(params[:otu_id]))  # !! NOT delete (see model)
    redirect_to :action => 'show', :id => @otu_group.id
  end

  def sort_otus
    params[:otu_groups_otu].each_with_index do |id, index|
      OtuGroupsOtu.update_all(['position=?', index+1], ['id=?', id])
    end
    notice "Updated OTU Order"
    render :nothing => true
  end

  def sort_by_select
    OtuGroupsOtu.find(:all, :conditions => {:otu_group_id => params[:id]}, :order => "otus.#{params[:sort_by].gsub(/\s/,"_")}", :include => :otu).each_with_index do |o, i|
      o.update_attribute(:position, i)
    end
    flash[:notice] = "Sorted by #{params[:sort_by]}."
    redirect_to :action => :show, :id => params[:id]
  end

  def make_default
    session['group_ids']['otu'] = params['id']
    redirect_to :action => 'list'
  end

  def clear_default
    session['group_ids']['otu'] = nil
    redirect_to :action => 'list'
  end

  def all_groups_summary
    @otu_groups = @proj.otu_groups
  end

  def edit_multiple_content
    if not (params[:content_type] && params[:content_type][:id].to_i > 0)
      flash[:notice] = "Pick a content type first."
      redirect_to :action => 'show', :id => params[:otu_group_id]  and return
    end

    @otu_group = OtuGroup.find(params[:otu_group_id], :include => :otus)
    @otus = @otu_group.otus
    @content_type = ContentType.find(params[:content_type][:id])
    @otu_cons = @content_type.contents(:proj_id => @proj.id)

    if params['submit'] == 'show'
      @show = ['show_multiple_content']
    else
      @show = ['edit_multiple_content']
    end

    @no_right_col = true
    render :action => 'show' #  :action => 'show', :id => params['otu_group_id']  and return
  end

  def update_multiple_content
    @content_type = ContentType.find_by_id(params[:content_type][:id])
    @otu_cons = @content_type.contents(:proj_id => @proj.id)
    @otu_group = OtuGroup.find_by_id(params[:otu_group][:id], :include => :otus)
    @otus = @otu_group.otus

   for otu in @otus
      con_h = {"text" => params['otu']["#{otu.id}"]["text"].strip}
      if @con = @otu_cons.detect {|c| c.otu_id == otu.id} # update or delete
        if con_h["text"] == "" # delete
          @con.destroy
        else # update
          @con.update_attributes(con_h)
        end
      else # insert or no action
        if con_h["text"] != "" # insert
          con_h['content_type_id'] = @content_type.id ## switched from con_type
          otu.contents.create(con_h)
        end
      end
    end
    flash[:notice] = 'updated content'
    redirect_to :action => 'show', :id => @otu_group.id
  end

  def update_content(state_h)
    @otu = Author.find(state_h['id'])
    @otu.update_attributes(state_h)
  end

  def otus_without_groups
    @otus = OtuGroup.otus_without_groups(@proj.id)
  end

  def auto_complete_for_otu_groups
    value = params[:term]
    method = params[:method]

    if value.nil?
      redirect_to(:action => 'index', :controller => 'otu_groups') and return
    else
      val = value.split.join('%') # hmm... perhaps should make this order-independent
      lim = case value.length
            when 1..2 then 10
            when 3..4 then 25
            else lim = false # no limits
            end
      @otu_groups = OtuGroup.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{val}%", val.gsub(/\%/, ""), @proj.id], :order => "name", :limit => lim )
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @otu_groups, :method => params[:method])
  end

  # merges (subtracts or adds)
  def combine
    @g1 = OtuGroup.find(params[:id])
    @g2 = OtuGroup.find(params[:group_to_find][:id])

    case params[:operation]

    when 'add'
      @g2.otus.collect{|o| @g1.add_otu(o) if not @g1.otus.include?(o)}
      notice "Added OTUs from #{@g2.display_name} to #{@g1.display_name}."
    when 'subtract'
      @g2.otus.collect{|o| @g1.remove_otu(o) if @g1.otus.include?(o)}
      notice "Subtracted OTUs from #{@g2.display_name} from #{@g1.display_name}."
    else
      notice "Problem with the OTU Group merge."
    end
    redirect_to :action => :show, :id => @g1.id
  end

  def download_kml
    otu_group = OtuGroup.find(params[:id])
    f = render_to_string(:partial => "shared/xml/kml", :locals => {:markers =>  otu_group.gmaps_markers})
    send_data(f, :filename => "kml_for_#{otu_group.name.gsub(/[^A-Za-z0-9_]/, '')}.kml", :type => "application/rtf", :disposition => "attachment")
  end

end
