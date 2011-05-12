class Public::LabelController < Public::BaseController

  def index 
    redirect_to :action => :index, :controller => '/public/ontology'
  end

  def show
    if @label = Label.find(:first, :conditions => {:id => params[:id], :proj_id => @proj.id}   )
      @ontology_classes = @label.ontology_classes # includes non-xrefed
      if @ontology_classes.size == 1
        redirect_to(:action => :show, :controller => :ontology_class, :id => @ontology_classes.first.id) and return
      end 
    else
      redirect_to :action => :index, :controller => '/public/ontology'
    end
  end

  def show_via_name
    if @label = Label.find(:first, :conditions => {:name => params[:id], :proj_id => @proj.id} )
      @ontology_classes = @label.ontology_classes # includes non-xrefed
      if @ontology_classes.size == 1
        redirect_to(:action => :show, :controller => :ontology_class, :id => @ontology_classes.first.id) and return
      else
        redirect_to(:action => :show, :id => (@label.plural_of_label ? @label.plural_of_label : @label) ) and return
      end 
    else
      redirect_to :action => :index, :controller => '/public/ontology'
    end
  end

  def list_all
    @labels = @proj.labels.all_singular_tied_to_ontology_classes
  end

end


