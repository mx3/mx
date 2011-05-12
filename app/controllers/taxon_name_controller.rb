class TaxonNameController < ApplicationController

  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  layout "layouts/application", :except => :show_ITIS_dump
  
  def index
    list
    render :action => 'list'
  end

  def list
    @taxon_name_pages, @taxon_names = paginate :taxon_name, :per_page => 25,
    :order_by => 'iczn_group, cached_display_name', :conditions =>  @proj.sql_for_taxon_names 
    if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def show
    id = params[:taxon_name][:id] if params[:taxon_name] # for ajax picker use
    id ||= params[:id]
    if @taxon_name = TaxonName.find(params[:id])
      @parents = @taxon_name.parents
      @children = @taxon_name.immediate_children
      session['taxon_name_view']  = 'show'
      @show = ['show_default'] 
    else
      flash[:notice] = "Taxon name not found."  
      redirect_to :action => 'list'
    end
  end

  def destroy
    begin
      TaxonName.find(params[:id]).destroy
    rescue
      flash[:notice] = "Error deleting taxon name, does it have childre, or is it attached to something, or used in permission or visibility settings?"  
    end
    redirect_to :action => 'list'
  end
  
  def rebuild_cached_display_name
    if @tn = TaxonName.find(params[:id]) 
      @tn.update_cached_display_name
      @tn.save
      flash[:notice] = 'The cached version of the name, as presently rendered in the header of this record, was recalculated successfully.'
    else
      flash[:notice] = 'Could not find the requested name!'
    end
    redirect_to :action => 'show', :id => @tn, :controller => 'taxon_name'
  end

  def add_type
    @type_specimen = TypeSpecimen.new(params[:type_specimen]) 
    begin
      @type_specimen.save!
      flash['notice'] = 'Successfully associated specimen as a type of this taxon name.'
    rescue
      @taxon_name = TaxonName.find(params[:type_specimen][:taxon_name_id])
      session['taxon_name_view']  = 'show_type_material'
      @specimens = @taxon_name.type_specimens # TypeSpecimen.find(:all, :conditions => ["taxon_name_id = #{@taxon_name.id}"])
      @no_right_col = true 
      @show = ['show_type_material'] # not redundant with above- @show necessary for multiple display of items
      render :action => :show and return
    end
    redirect_to(:action => 'show_type_material', :id => params[:type_specimen][:taxon_name_id]) and return
  end
  
  def remove_type
    o = TypeSpecimen.find(params[:id])
    o.destroy
    redirect_to(:action => 'show_type_material', :id => o.taxon_name_id) and return
  end
 
  def show_material
    @taxon_name = TaxonName.find(params[:id])
    session['taxon_name_view']  = 'show_material'
    ids =  @taxon_name.full_set.collect{|t| t.id}.join(",")
    @ipt_records = IptRecord.find(:all, :conditions =>  "taxon_name_id in (#{ids}) AND proj_id = #{$proj_id}" )

    if ['species', 'genus', 'family', 'variety'].include?(@taxon_name.iczn_group)
      @specimens = Specimen.by_proj(@proj).with_current_determination_and_member_of_taxon(@taxon_name)
      @lots = Lot.by_proj(@proj).member_of_taxon(@taxon_name)
    else
      @specimens = []
      @lots = []
    end
    
    @no_right_col = true 
    @show = ['show_material'] 
    render :action => 'show'
  end

  def show_type_material
    @taxon_name = TaxonName.find(params[:id])
    session['taxon_name_view']  = 'show_type_material'
    @specimens = @taxon_name.type_specimens # TypeSpecimen.find(:all, :conditions => ["taxon_name_id = #{@taxon_name.id}"])
    @no_right_col = true 
    @show = ['show_type_material'] # not redundant with above- @show necessary for multiple display of items
    render :action => 'show'
  end

  def show_summary
    @klass = "TaxonName"
    @taxon_name = TaxonName.find(params[:id])
    @no_right_col = true 
    session['taxon_name_view'] = 'show_summary'
    @show = ['show_summary'] # not redundant with above- @show necessary for multiple display of items
    render :action => 'show'
  end

  def show_ITIS_dump
    @taxon_name = TaxonName.find(params[:id])
    @list = @taxon_name.full_set
    session['taxon_name_view']  = 'show_ITIS_dump'
    @header = "ITIS Dump (#{@list.size})"
    @show = ['show_ITIS_dump'] # not redundant with above- @show necessary for multiple display of items
    render(:partial => 'show_ITIS_dump')
  end
  
  def show_taxon_name_report
    @taxon_name = TaxonName.find(params[:id])
    @list = @taxon_name.full_set
    @list.sort!{|a,b| a.name.downcase <=> b.name.downcase}
    render(:layout => 'minimal') 
  end

  def download_taxon_name_report
    @taxon_name = TaxonName.find(params[:id])
    @list = @taxon_name.full_set
    @list.sort!{|a,b| a.name.downcase <=> b.name.downcase}
    f = render_to_string(:partial => '/taxon_name/reports/taxon_name_report')
    send_data(f, :filename => "#{@taxon_name.name}_report.tab", :type => "application/rtf", :disposition => "attachment")
  end

  def show_images
    @taxon_name = TaxonName.find(params[:id])
  
    @list = @taxon_name.full_set
   
    @parents = @taxon_name.parents
    @image_descriptions = @taxon_name.image_descriptions(@proj.id) 
    
    session['taxon_name_view']  = 'show_images'
    @show = ['show_images'] # not redundant with above- @show necessary for multiple display of items
    render :action => 'show'
  end
    
  def show_immediate_child_otus
    @taxon_name = TaxonName.find(params[:id])
    @list = @proj.otus.with_taxon_name(@taxon_name) 
    session['taxon_name_view']  = 'show_immediate_child_otus'
    @header = "Immediate child OTUs <i>in this project</i>"
    @show = ['show_list'] # not redundant with above- @show necessary for multiple display of items
    @no_right_col = true 
    render :action => :show
  end

  
  def show_all_children
    @taxon_name = TaxonName.find(params[:id])
  
    @list = @taxon_name.children ## HMM
    
    session['taxon_name_view']  = 'show_immediate_children'
    @header = "Immediate children"
    @show = ['show_list'] # not redundant with above- @show necessary for multiple display of items
    render :action => :show
  end

    
  def show_taxonomic_history
    @taxon_name = TaxonName.find(params[:id])
    @taxon_hists = @taxon_name.taxon_hists # visibility isn't an issue if you've got this far (hhm yes it might be)

    session['taxon_name_view']  = 'show_taxonomic_history'
    @header = "Immediate children"
    @show = ['show_taxon_hists'] # not redundant with above- @show necessary for multiple display of items
    @taxon_hist = TaxonHist.new
    @no_right_col = true
    @in_taxon_hists = false
    
    render :action => :show
  end
  
  def show_tags
    @taxon_name = TaxonName.find(params[:id])
    @tags = @taxon_name.tags.group_by(&:keyword)  

    session['taxon_name_view']  = 'show_tags'
    @header = "Tags"
    @show = ['show_tags'] # not redundant with above- @show necessary for multiple display of items
    @tag = Tag.new
    @no_right_col = true
    @in_taxon_hists = false
    render :action => :show
  end
  
  def new
    @taxon_name = TaxonName.new
  end

  def create
    @taxon_name = TaxonName.create_new(:taxon_name => params[:taxon_name], :person => session[:person])

    begin TaxonName.transaction do
      if @taxon_name.errors.size > 0
        raise @taxon_name.errors
      end

      @taxon_name.save!

      if @identifier = Identifier.create_new(params[:identifier].merge(:object => @taxon_name))
        @identifier.save!
      end

      if @taxon_name.errors.size > 0
        render :action => :new
      else
        if params[:commit] == 'Create and create associated OTU'
          Otu.create!(:taxon_name => @taxon_name)
        end
        flash[:notice] = 'TaxonName was successfully created.'
        redirect_to :action => :show, :id => @taxon_name.id and return
      end
    end

    rescue  Exception => e 
      flash[:notice] = e.message 
      render :action => :new and return
    end
  end
  
  def edit
    @taxon_name = TaxonName.find(params[:id])
    if !@taxon_name.in_ranges?(session[:person].editable_taxon_ranges)
      flash[:notice] = "You don't have permission to edit that name.  Contact an administrator if you think there is a problem."
      redirect_to :action => :list and return
    end
  end

  def update
    @taxon_name = TaxonName.find(params[:id])
    begin
      TaxonName.transaction do
        @taxon_name.update_attributes(params[:taxon_name])
        if not (@taxon_name.temp_parent_id.to_i == @taxon_name.parent_id.to_i)
          @taxon_name.move_checking_permissions(TaxonName.find(@taxon_name.temp_parent_id), TaxonName.find(@taxon_name.parent_id), session[:person]) # new_parent, old_parent, person
        end
        if @taxon_name.errors.size > 0
          render :action => :edit and return
        end
        if @identifier = Identifier.create_new(params[:identifier].merge(:object => @taxon_name))
          @identifier.save!
        end
      end
    rescue ActiveRecord::RecordInvalid => e 
      flash[:notice] = "Failed to update the record: #{e.message}."
      render :action => :edit and return
    end
    flash[:notice] = 'Taxon name was successfully updated.'
    redirect_to :action => :show, :id => @taxon_name
  end

  def visibility
    if request.post?
      TaxonName.set_visibility(params.update(:proj_id => @proj.id))
    end
    @names_in = @proj.proj_taxon_names(true) 
  end
   
  def toggle_public
    c = ProjTaxonName.find(params[:id])
    c.is_public = !c.is_public
    c.save
    redirect_to :action => :visibility
  end
 
  # -- Action for the ajax TaxonName picker -- 
  # Relies on the following componenets
  # - the partial taxon_name/picker, which contains the javascript
  # - this action, which is called by the picker via ajax
  # - Proj.sql_for_taxon_names, which provides just that and is called in this action
  # - TaxonName.find_for_auto_complete, which uses the sql and is ugly
  # - auto_complete_result_with_ids, in application helper, which renders the result
  # - format_taxon_name_for_auto_complete, in application_helper, which is called by the above method
  def auto_complete_for_taxon_name
    # because i am using find_by_sql and joining the TN table to itself, i need to alias 
    # one of the TN tables and use that alias in all of the where and order by conditions, etc. -- not very clean
    table_name = "tn" 
    @tag_id_str = params[:tag_id]
    value = params[@tag_id_str.to_sym]
    
    if params[:use_proj] == 'false'
      proj_sql = ""
    else
      proj_sql = "AND (" + @proj.sql_for_taxon_names(table_name) + ")" 
    end
   
    # need to get the values to split (like in OTUs)
    
    # possible conditions are [all, genus, species, family]
    if params[:name_group] == 'all'
      conditions = ["(#{table_name}.name LIKE ? or #{table_name}.id = ? or #{table_name}.author LIKE ? or #{table_name}.year = ?) #{proj_sql}", "#{value.downcase}%", "#{value.downcase}%", "#{value}%", "#{value.downcase}" ]
    else
      conditions = ["(#{table_name}.name LIKE ?  or #{table_name}.author LIKE ? or #{table_name}.year = ?) AND #{table_name}.iczn_group = ? #{proj_sql}", "#{value.downcase}%",  "#{value.downcase}%", "#{value.downcase}", params[:name_group]]
    end
    @taxon_names = TaxonName.find_for_auto_complete(conditions, table_name)
    # this is found in application_helper, and helps the auto complete behave like a select 
    render :inline => "<%= auto_complete_result_with_ids(@taxon_names,
     'format_taxon_name_for_auto_complete', @tag_id_str) %>"
  end

  def search
    @taxon_name = TaxonName.new
  end
  

  # runs from search, should AJAX this
  def search_list
    genus = params[:genus] || ""
    species = params[:species] || ""
    author = params[:author] || ""
    other = params[:other] || ""
    
  #  @proj.search_taxa(genus, species, author, other)
    
    if genus != ""
      @taxon_names_pages, @taxon_names = paginate :taxon_name, 
        :include => 'type_geog',  :join => TaxonName.clean(["LEFT JOIN (SELECT id as genus_id, l, r from taxon_names WHERE name LIKE ? AND iczn_group = 'genus') AS g 
           ON taxon_names.l > g.l AND taxon_names.r < g.r", "#{genus}%"]),  :conditions => [ "((taxon_names.name LIKE ?) AND (author LIKE ?) AND ((type_locality LIKE ?) OR (geogs.name LIKE ?)) AND (#{@proj.sql_for_taxon_names('taxon_names')}) AND (genus_id IS NOT NULL))",
          "#{species}%", "#{author}%", "%#{other}%" , "%#{other}%"  ], 
         :order_by => 'taxon_names.l', 
         :per_page => 30
    else
      @taxon_names_pages, @taxon_names = paginate :taxon_name, 
      :include => 'type_geog',
        :conditions => [ "((taxon_names.name LIKE ?) AND (author LIKE ?) AND (type_locality LIKE ? OR geogs.name LIKE ?) AND (#{@proj.sql_for_taxon_names}))",
         "#{species}%", "#{author}%", "%#{other}%", "%#{other}%"  ], 
        :order_by => 'taxon_names.l', 
        :per_page => 30
    end  
    render :layout => false
  end

  def batch_load
  end

  # need to update all batch methods to logic like this
  def batch_verify
    begin
      raise ParseError.new("You must provide a parent taxon name and an ICZN group.") if params[:taxon_name][:parent_id].blank? || params[:taxon_name][:iczn_group].blank?

      @taxon_names = TaxonName.load_from_batch(params)
      @taxon_name = TaxonName.find(params[:taxon_name][:parent_id])
      raise ParseError.new("You don't have permission to edit that name. Contact an administrator if you think there is a problem.") if !@taxon_name.in_ranges?(session[:person].editable_taxon_ranges)
      
      @iczn_group = params[:taxon_name][:iczn_group] 
      @ref = Ref.find(params[:taxon_name][:ref_id]) if params[:term] && !params[:taxon_name][:ref_id].blank?
 
    rescue ParseError => e
      flash[:notice] = "#{e}"       
      redirect_to :action => :batch_load and return
    end
  end

  def batch_create
    count = TaxonName.create_from_batch(params.update(:person => session[:person]))
    flash[:notice] = "Created #{count} new names."
    redirect_to :action => :list
  end
  
  def test
    @x = Hodb_xml
  end

end
