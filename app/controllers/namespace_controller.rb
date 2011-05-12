class NamespaceController < ApplicationController
   verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  # this overrides the authorize? method defined in lib/login_system.rb
  def authorize?(person)
    person.is_admin?
  end

  def index
    list
    render :action => 'list'
  end

  def list
    @namespace_pages, @namespaces = paginate :namespace, :per_page => 50, :order => :name
  end

  def show
    @namespace = Namespace.find(params[:id])
  end

  def new
    @namespace = Namespace.new
  end

  def create
    @namespace = Namespace.new(params[:namespace])  
    if @namespace.save
      flash[:notice] = 'Namespace was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @namespace = Namespace.find(params[:id])
  end

  def update
    $proj_id = nil
    $merge = true # This flag skips project ownership checks necessary for cascading updates on Identifiers. 
    @namespace = Namespace.find(params[:id])
    if @namespace.update_attributes(params[:namespace])
      flash[:notice] = 'Namespace was successfully updated.'
      redirect_to :action => 'show', :id => @namespace
    else
      render :action => 'edit'
    end
    $merge = false
  end

  def destroy
    Namespace.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def auto_complete_for_namespace
    @namespaces = Namespace.auto_complete_search_result(params)
    render :inline => "<%= auto_complete_result_with_ids(@namespaces, 'format_obj_for_auto_complete', @tag_id_str) %>"
  end

end
