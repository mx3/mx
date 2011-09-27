class GeneGroupController < ApplicationController
 verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  
  def index
    list
    render :action => 'list'
  end

  def list
    @gene_group_pages, @gene_groups = paginate :gene_group, :per_page => 30, 
    :order_by => 'name',  :conditions => "(proj_id = #{@proj.id})"
  end

  def show
    id = params[:gene_group][:id] if params[:gene_group]
    id ||= params[:id]
  
    @gene_group = GeneGroup.find(id)
    @genes_in = @gene_group.genes
    @genes_out = @proj.genes - @genes_in
  end

  def new
    @gene_group = GeneGroup.new
  end

  def create
    @gene_group = GeneGroup.new(params[:gene_group])
  
    if @gene_group.save
      flash[:notice] = 'GeneGroup was successfully created.'
      redirect_to :action => 'show', :id => @gene_group.id
    else
      render :action => 'new'
    end
  end

  def edit
    @gene_group = GeneGroup.find(params[:id])
  end

  def update
    @gene_group = GeneGroup.find(params[:id])
    if @gene_group.update_attributes(params[:gene_group])
      flash[:notice] = 'GeneGroup was successfully updated.'
      redirect_to :action => 'show', :id => @gene_group
    else
      render :action  => 'edit'
    end
  end

  def destroy
    GeneGroup.find(params[:id]).destroy
    redirect_to :action => 'list'
  end


  def add_gene
    @gene_group = GeneGroup.find(params[:id])
    if params[:gene_id]
      g = Gene.find(params[:gene_id])
      @gene_group.genes << g
      @gene_group.save!
    end   
    redirect_to :action => 'show', :id => @gene_group.id    
  end
  
  def remove_gene
    @gene_group = GeneGroup.find(params[:id])
    @gene_group.genes.delete(Gene.find(params[:gene_id]))  
    redirect_to :action => 'show', :id => @gene_group.id    
  end

  def auto_complete_for_gene_group
    value = params[:term]
    if value.nil? 
      redirect_to(:action => 'index', :controller => 'gene_group') and return
    else
      val = value.split.join('%') 
      lim = case value.length
        when 1..2 then  10
        when 3..4 then  25
        else lim = false # no limits
      end 
      @gene_groups = GeneGroup.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{value}%", value.gsub(/\%/, ""), @proj.id], :order => "name", :limit => lim )
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @gene_groups, :method => params[:method])
  end
  
  
end
