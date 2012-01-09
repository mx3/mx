class GenesController < ApplicationController
     
  def index
    list
    render :action => 'list'
  end

  def list
    @genes = Gene.by_proj(@proj)
        .page(params[:page])
        .per(20)
  end

  def show
    id = params[:gene][:id] if params[:gene]
    id ||= params[:id]
    @gene = Gene.find(id)
  end

  def new
    @gene = Gene.new
  end

  def create
    @gene = Gene.new(params[:gene])
    if @gene.save
      flash[:notice] = 'Gene was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @gene = Gene.find(params[:id])
  end

  def update
    @gene = Gene.find(params[:id])
    if @gene.update_attributes(params[:gene])
      flash[:notice] = 'Gene was successfully updated.'
      redirect_to :action => 'show', :id => @gene
    else
      render :action => 'edit'
    end
  end

  def destroy
    Gene.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def sort_genes
    params[:genes].each_with_index do |id, index|
      Gene.update_all(['position=?', index+1], ['id=?', id])
    end
    render :nothing => true
  end

  def sort
    @genes = @proj.genes
  end

  def auto_complete_for_genes
    value = params[:term]
    if value.nil?
      redirect_to(:action => 'index', :controller => 'genes') and return
    else
      val = value.split.join('%') # hmm... perhaps should make this order-independent
      lim = case value.length
            when 1..2 then  10
            when 3..4 then  25
            else lim = false # no limits
            end 
      @genes = Gene.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{val}%", val.gsub(/\%/, ""), @proj.id], :order => "name", :limit => lim )
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @genes, :method => params[:method])
  end

  
end
