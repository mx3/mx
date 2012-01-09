class TaxonHistsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list 
    # Only show those attached to visible names
    @taxon_hists = TaxonHist.where(@proj.sql_for_taxon_names('taxon_names')).includes(:taxon_name).page(params[:page]).per(20)  
  end

  def show
    id ||= params[:taxon_hist][:id] if params[:taxon_hist] # for ajax picker use
    id = params[:id]
    if id == nil
      flash[:notice] = $ERR_NO_ID
      redirect_to :action => 'list' and return
    end
    @taxon_hist = TaxonHist.find(id)
  end

  def new
    @taxon_hist = TaxonHist.new
    @in_taxon_hists = true
  end

  def create 
    @taxon_hist = TaxonHist.new(params[:taxon_hist])
    if @taxon_hist.save
      flash[:notice] = 'TaxonHist was successfully created.'
      if params[:taxon_hist]
        @show = ['show_taxon_hists']
        @taxon_name = TaxonName.find(params[:taxon_hist][:taxon_name_id])
        @in_taxon_hists = false
        @no_right_col = true
        redirect_to :action => 'show_taxonomic_history', :id => @taxon_name, :controller => 'taxon_names'
      else 
        redirect_to :action => 'list'
      end
    else # a bad way to barf
      @taxon_name = TaxonName.new
      @in_taxon_hists = true
      render :action => 'new'
    end
  end

  def edit
    @taxon_hist = TaxonHist.find(params[:id])
    @in_taxon_hists = true
  end

  def update
    @taxon_hist = TaxonHist.find(params[:id])
    if @taxon_hist.update_attributes(params[:taxon_hist])
      flash[:notice] = 'TaxonHist was successfully updated.'
      if params[:in_taxon_hists] == 1
        redirect_to(:action => 'show', :id => @taxon_hist.id)              
      else
        redirect_to(:action => 'show_taxonomic_history', :controller => 'taxon_names', :id => @taxon_hist.taxon_name_id)
      end 
    else
      render :action => 'edit'
    end
  end

  def destroy
    if t = TaxonHist.find(params[:id])
      t.destroy
    else
      flash[:notice] = $ERR_OBJ_NOT_FOUND
    end
    redirect_to :action => 'list'
  end

  def auto_complete_for_taxon_hists
    @taxon_hists = TaxonHist.find_for_auto_complete(params[:term].split, @proj.sql_for_taxon_names("taxon_names"))    
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @taxon_hists, :method => params[:method])
  end

end
