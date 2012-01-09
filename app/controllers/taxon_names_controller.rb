class TaxonNamesController < ApplicationController

  layout "layouts/application", :except => :show_ITIS_dump
  
  def index
    list
    render :action => 'list'
  end

  def list
    @taxon_names = TaxonName.where(@proj.sql_for_taxon_names).page(params[:page]).per(20).order('iczn_group, cached_display_name')
  end

  def show
    id = params[:taxon_name][:id] if params[:taxon_name] # for ajax picker use
    id ||= params[:id]
    if @taxon_name = TaxonName.find(params[:id])
      @parents = @taxon_name.parents
      @children = @taxon_name.immediate_children
      @show = ['default'] 
    else
      notice = "Taxon name not found."  
      redirect_to :action => 'list'
    end
  end

  def show_material
    @taxon_name = TaxonName.find(params[:id])
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
    render :action => 'show'
  end

  def show_type_material
    @taxon_name = TaxonName.find(params[:id])
    @specimens = @taxon_name.type_specimens # TypeSpecimen.find(:all, :conditions => ["taxon_name_id = #{@taxon_name.id}"])
    @no_right_col = true 
    render :action => 'show'
  end

  def show_summary
    @klass = "TaxonName"
    @taxon_name = TaxonName.find(params[:id])
    @no_right_col = true 
    render :action => 'show'
  end



  def show_images
    @taxon_name = TaxonName.find(params[:id])
    @list = @taxon_name.full_set
    @parents = @taxon_name.parents
    @image_descriptions = @taxon_name.image_descriptions(@proj.id) 
    render :action => 'show'
  end
    
  def show_immediate_child_otus
    @taxon_name = TaxonName.find(params[:id])
    @list = @proj.otus.with_taxon_name(@taxon_name) 
    @header = "Immediate child OTUs <i>in this project</i>"
    @show = ['list'] 
    @no_right_col = true 
    render :action => :show
  end

  def show_all_children
    @taxon_name = TaxonName.find(params[:id])
    @list = @taxon_name.children ## HMM
    @header = "Immediate children"
    @show = ['list'] # not redundant with above- @show necessary for multiple display of items
    render :action => :show
  end

  def show_taxonomic_history
    @taxon_name = TaxonName.find(params[:id])
    @taxon_hists = @taxon_name.taxon_hists # visibility isn't an issue if you've got this far (hhm yes it might be)
    @taxon_hist = TaxonHist.new
    @no_right_col = true
    @in_taxon_hists = false
    render :action => :show
  end
  
  def show_tags
    @taxon_name = TaxonName.find(params[:id])
    @tags = @taxon_name.tags.group_by(&:keyword)  
    @header = "Tags"
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
        notice = 'TaxonName was successfully created.'
        redirect_to :action => :show, :id => @taxon_name.id and return
      end
    end

    rescue  Exception => e 
      notice = e.message 
      render :action => :new and return
    end
  end
  
  def edit
    @taxon_name = TaxonName.find(params[:id])
    if !@taxon_name.in_ranges?(session[:person].editable_taxon_ranges)
      notice = "You don't have permission to edit that name.  Contact an administrator if you think there is a problem."
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
      notice = "Failed to update the record: #{e.message}."
      render :action => :edit and return
    end
    notice = 'Taxon name was successfully updated.'
    redirect_to :action => :show, :id => @taxon_name
  end

  def destroy
    begin
      TaxonName.find(params[:id]).destroy
    rescue
      notice = "Error deleting taxon name, does it have children, or is it attached to something, or used in permission or visibility settings?"  
    end
    redirect_to :action => 'list'
  end
 
  def report_ITIS_dump
    @taxon_name = TaxonName.find(params[:id])
    @list = @taxon_name.full_set
    @header = "ITIS Dump (#{@list.size})"
    render :template => '/taxon_names/reports/ITIS_dump'
  end
  
  def report_taxon_names
    @taxon_name = TaxonName.find(params[:id])
    @list = @taxon_name.full_set
    @list.sort!{|a,b| a.name.downcase <=> b.name.downcase}
    render :template => '/taxon_names/reports/taxon_names', :layout => 'minimal' # TODO mx3: minimal layout not working
  end


  def rebuild_cached_display_name
    if @tn = TaxonName.find(params[:id]) 
      @tn.update_cached_display_name
      @tn.save
      notice = 'The cached version of the name, as presently rendered in the header of this record, was recalculated successfully.'
    else
      notice = 'Could not find the requested name!'
    end
    redirect_to :action => 'show', :id => @tn, :controller => 'taxon_names'
  end

  def download_taxon_name_report
    @taxon_name = TaxonName.find(params[:id])
    @list = @taxon_name.full_set
    @list.sort!{|a,b| a.name.downcase <=> b.name.downcase}
    f = render_to_string(:partial => '/taxon_names/reports/taxon_name_report')
    send_data(f, :filename => "#{@taxon_name.name}_report.tab", :type => "application/rtf", :disposition => "attachment")
  end

  # TODO: make it a show
  def add_type
    @type_specimen = TypeSpecimen.new(params[:type_specimen]) 
    begin
      @type_specimen.save!
      flash['notice'] = 'Successfully associated specimen as a type of this taxon name.'
    rescue
      @taxon_name = TaxonName.find(params[:type_specimen][:taxon_name_id])
      @specimens = @taxon_name.type_specimens # TypeSpecimen.find(:all, :conditions => ["taxon_name_id = #{@taxon_name.id}"])
      @no_right_col = true 
      @show = ['type_material'] 
      render :action => :show and return
    end
    redirect_to(:action => 'show_type_material', :id => params[:type_specimen][:taxon_name_id]) and return
  end
  
  def remove_type
    o = TypeSpecimen.find(params[:id])
    o.destroy
    redirect_to(:action => 'show_type_material', :id => o.taxon_name_id) and return
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
 
  def auto_complete_for_taxon_names
    table_name = "tn"  # alias for the TaxonName joins needed
    value = params[:term]
    if params[:use_proj] == 'false'
      proj_sql = ""
    else
      proj_sql = "AND (" + @proj.sql_for_taxon_names(table_name) + ")" 
    end
    
    # possible conditions are [all, genus, species, family]
    if params[:name_group] == 'all'
      conditions = ["(#{table_name}.name LIKE ? or #{table_name}.id = ? or #{table_name}.author LIKE ? or #{table_name}.year = ?) #{proj_sql}", "#{value.downcase}%", "#{value.downcase}%", "#{value}%", "#{value.downcase}" ]
    else
      conditions = ["(#{table_name}.name LIKE ?  or #{table_name}.author LIKE ? or #{table_name}.year = ?) AND #{table_name}.iczn_group = ? #{proj_sql}", "#{value.downcase}%",  "#{value.downcase}%", "#{value.downcase}", params[:name_group]]
    end

    @taxon_names = TaxonName.find_for_auto_complete(conditions, table_name)
    data = @taxon_names.collect do |t|
      {:id=> t.id,
       :label=> t.display_name(:type => :selected),
       :response_values=> {
        # 'taxon_name[id]' => t.id, <- pretty sure this will bork things.
        params[:method] => t.id  
      },
       :label_html => render_to_string(:partial => 'shared/autocomplete/taxon_name.html', :object => t)
      }
    end
    render :json => data 
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
      notice = "#{e}"       
      redirect_to :action => :batch_load and return
    end
  end

  def batch_create
    count = TaxonName.create_from_batch(params.update(:person => session[:person]))
    notice = "Created #{count} new names."
    redirect_to :action => :list
  end
  
  def test
    @x = Hodb_xml
  end

end
