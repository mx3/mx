class LotsController < ApplicationController
  
  layout 'layouts/application',  :except => :grand_summary_xsl
  
  def index
    list
    render :action => :list
  end

  def list  
    @lots = Lot.by_proj(@proj)
    .page(params[:page])
    .per(20)
    .includes(:otu, :ce, :repository, {:identifiers => :namespace}, :repository, :updator, :creator, {:otu => {:taxon_name => :parent}}, :tags)
  end

  def show
    id = params[:lot][:id] if params[:lot] # for ajax picker use
    id ||= params[:id]
  
    if @lot = Lot.find(id, :include => [{:identifiers => :namespace},:repository, :updator,:creator, {:otu => :taxon_name}, :ce, :tags])
    else
     flash[:notice] =  "Lot #{id} not found."  
     redirect_to :action => :list
   end
    @show = ['default'] 
  end

  # just set some params
  def new
    @lot = Lot.new
    params_for_new_lot
  end

  def create
    @lot = Lot.new(params[:lot])

    begin
      Lot.transaction do
        @lot.save!

        if @identifier = Identifier.create_new(params[:identifier].merge(:object => @lot))
          @identifier.save!
        end

        debugger
        flash[:notice] = 'Lot was successfully created.'

      end

    rescue Exception => e
      flash[:notice] = e.message 
      @namespaces = Namespace.find(:all).collect {|t| [ t.display_name(:type => :for_select_list), t.id ] }
      render :action => :new and return
    end

    if params[:commit] == 'Create, clone and next'
      @lot = Lot.new
      params_for_new_lot
      @identifier = @lotID
      @identifier.identifier = ''
      render :action => 'new' and return
    elsif params[:commit] == 'Create and next' 
      @lot = Lot.new
      @identifier = Identifier.new
      params_for_new_lot
      render :action => :new and return
    else
      redirect_to :action => :show, :id => @lot
    end

  end

  def divide
    @old_lot = Lot.find(params[:id])
    if @lot = @old_lot.divide(params)
      flash[:notice] = "Divided from lot #{@lot.id}, showing new Lot."
    else
     @lot = @old_lot
     flash[:notice] = "Failed to divide lot."
    end
    redirect_to :action => :show, :id => @lot.id
  end

  def edit
    @lot = Lot.find(params[:id])
    params_for_new_lot
  end

  def update
    @lot = Lot.find(params[:id], :include => [:identifiers, :ce, :otu])

    begin
      Lot.transaction do
        @lot.update_attributes(params[:lot])

        if @identifier = Identifier.create_new(params[:identifier].merge(:object => @lot))
          @identifier.save!
        end

        flash[:notice] = 'Lot was successfully updated.' ## not really, see below
        redirect_to :action => :show, :id => @lot.id and return
      end
    rescue Exception => e
      flash[:notice] = e.message 
      @namespaces = Namespace.find(:all).collect {|t| [ t.display_name(:type => :for_select_list), t.id ] }
      render :action => :edit
    end
  end

  def destroy
    Lot.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def auto_complete_for_lots
    value = params[:term]
    @lots = Lot.find_for_auto_complete(value)
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @lots, :method => params[:method])
  end

  # returns variables for grand_summary functions
  def gs
     @records = Lot.find_by_sql(["SELECT l.proj_id, l.notes, lis.identifier as i, o.id, Sum(l.key_specimens) AS nsk, Sum(l.value_specimens) AS nsv, sum(l.key_specimens + l.value_specimens) AS ns
                    FROM (lots AS l LEFT JOIN lot_identifiers AS lis ON l.id = lis.lot_id) LEFT JOIN otus AS o ON l.otu_id = o.id
                    GROUP BY lis.identifier, o.id
                    HAVING (l.proj_id = ?);", @proj.id])
     @tot_unique_ids = Lot.find_by_sql(["Select distinct lis.identifier FROM (lots AS l LEFT JOIN lot_identifiers AS lis ON l.id = lis.lot_id) Where (l.proj_id = ?);", @proj.id]).size
     @tot_specimens = @records.inject(0) do |sum, o| sum += o.ns.to_i end
   end
  
  def grand_summary
    gs
    render :partial => 'grand_summary'
  end

  def grand_summary_xsl
    # experimental, likely only works with Office 2003
    headers['Content-Type'] = "application/vnd.ms-excel" 
    headers['Content-Disposition'] = 'attachment; filename="lots_grand_summary.xls"'
    headers['Cache-Control'] = ''
    @columns = ['Identifier', 'Otu', '#specimens']
    gs
  end 

  def clone_to_specimen
    if @l = Lot.find(params[:id])
      begin
          Specimen.transaction do
            @s = Specimen.new
            @s.ce_id = @l.ce_id if @l.ce_id
            @s.notes = "Cloned from lot #{@l.id}." + (@l.notes.size > 0 ? " #{@l.notes}" : '')
            @s.repository_id = @l.repository_id if @l.repository_id
            @s.dna_usable = @l.dna_usable
            @s.temp_ce = @l.ce_labels if @l.ce_labels
            @s.save
            
            @d = SpecimenDetermination.new
            @d.otu_id = @l.otu_id  # if @l.otu_id
            @d.specimen = @s
            @d.save
          end
          flash[:notice] = 'Specimen cloned extracted from lot.'
          redirect_to(:action => 'edit', :controller => 'specimens', :id => @s) and return
      rescue
       flash[:notice] = "Something went wrong in clone" 
      end
    end
    redirect_to :action => 'show', :id => @l
  end
  
  def extract_specimen
      if @l = Lot.find(params[:id])
      begin
          Specimen.transaction do
            @s = Specimen.new
            @s.ce_id = @l.ce_id if @l.ce_id
            @s.notes = "Cloned from lot #{@l.id}.\n" + (@l.notes.size > 0 ? " #{@l.notes}" : '')
            @s.repository_id = @l.repository_id if @l.repository_id
            @s.dna_usable = @l.dna_usable
            @s.temp_ce = @l.ce_labels if @l.ce_labels
            @s.save
            
            @d = SpecimenDetermination.new
            @d.otu_id = @l.otu_id  # if @l.otu_id
            @d.specimen = @s
            @d.save
            
            if params[:remove_from] == 'value'
              @l.value_specimens = @l.value_specimens - 1
            elsif params[:remove_from] == 'key'
              @l.key_specimens = @l.key_specimens - 1
            else
              raise "something went wrong"
            end
            
            @l.save
          end
          flash[:notice] = 'Specimen successfully extracted from lot.'
          redirect_to(:action => 'edit', :controller => 'specimens', :id => @s) and return
      rescue
       flash[:notice] = "Something went wrong in clone" 
      end
    end
    redirect_to :action => 'show', :id => @l
  end

  def destroy_identifier
    Identifier.find(params[:id]).destroy
    flash[:notice] = "Identifier destroyed."
    redirect_to :back
  end 

  private
 
  def params_for_new_lot
    @namespaces = Namespace.find(:all).collect {|t| [ t.display_name(:type => :for_select_list), t.id ] }
    @identifier = Identifier.new(:addressable_type => 'Lot')

    if params[:lock_otu]
      @lock_otu = true
      session[:default_otu_id] = params[:lot][:otu_id]
    else
      session[:default_otu_id] = nil
    end

    @lot.otu_id = session[:default_otu_id] if session[:default_otu_id] 

    if @proj.default_specimen_identifier_namespace && @identifier.namespace.blank?
      @identifier.namespace = @proj.default_specimen_identifier_namespace
    end

    @lot.repository_id = session[:person].pref_default_repository_id if @lot.repository_id.blank?
  end
 
 end
