class Api::OntologyController < ApplicationController

  def index
    redirect_to "http://#{HELP_WIKI}/index.php/App/API/Ontology"
  end

  # http://127.0.0.1:3000/projects/32/api/ontology/ontology_class/HAO_0001353
  def ontology_class
    if id = Ontology::OntologyMethods.xref_from_params(params[:id])
      if @ontology_class = OntologyClass.find(:first, :conditions => {:proj_id => @proj.id, :xref => id})
        respond_to do |format|
          format.html { redirect_to :action => :show_expanded, :id => @ontology_class.id, :controller => '/public/ontology_classes'}
          format.json {
            render :json => @ontology_class.ontology_class_as_json, :content_type => "text/html" # application/json <- firefox downloads as file
          }
          format.xml {redirect_to "http://www.ontobee.org/browser/rdf.php?o=HAO&iri=http://purl.obolibrary.org/obo/#{id.gsub(/:/, '_')}"} # gives us RDF back 
        end
      else 
        render :file => "#{Rails.root}/public/404.html", :status => :not_found and return 
      end
    else
      render :file => "#{Rails.root}/public/400.html", :status => :bad_request and return
    end
  end

  def analyze
    # sanitize!
    if @result = Ontology::OntologyMethods::analysis_as_json(:text => params[:id],:proj_id => @proj.id)
      render :json => @result
    else
      render :file => "#{Rails.root}/public/404.html", :status => :not_found and return
    end
  end

  def label 
    if @label = Label.find(:first, :conditions => {:proj_id => @proj.id, :name => params[:id]})
      render :json => @label.as_json
    else
      render :file => "#{Rails.root}/public/404.html", :status => :not_found and return
    end
  end

  def uri_markup
    # sanitize!
    if @result = Ontology::OntologyMethods::markup_as_json(:text => params[:id],:proj_id => @proj.id, :mode => 'bioportal_uri_link')
      render :json => @result
    else
      render :file => "#{Rails.root}/public/404.html", :status => :not_found and return
    end
  end

  def glossary_markup
    # sanitize!
    if @result = Ontology::OntologyMethods::markup_as_json(:text => params[:id],:proj_id => @proj.id, :mode => 'api_link')
      render :json => @result
    else
      render :file => "#{Rails.root}/public/404.html", :status => :not_found and return
    end
  end

  def svg 
    if id = Ontology::OntologyMethods.xref_from_params(params[:id])
      if @ontology_class = OntologyClass.find(:first, :conditions => {:proj_id => @proj.id, :xref => id})
        respond_to do |format|
          format.html {
            render :file => "#{Rails.root}/public/400.html", :status => :bad_request and return
          }
          format.json {
            render :json => @ontology_class.svg_as_json, :content_type => "text/html"
          }
        end
      else 
        render :file => "#{Rails.root}/public/404.html", :status => :not_found and return # record not found
      end
    else
      render :file => "#{Rails.root}/public/400.html", :status => :bad_request and return
    end
  end

  def obo_file
    # TODO: return null if proj.is_ontology_private
    @time = Time.now()
    @relationships = @proj.object_relationships.reject{|r| Ontology::OntologyMethods::OBO_TYPEDEFS.include?(r.interaction)}  
    @xref_keywords = @proj.keywords.that_are_xrefs

    # a little check
    if @proj.ontology_namespace.blank?
      flash[:notice] = "Project not fully configured to dump OBO files.  Check that ontology namespace is set."
      redirect_to :controller => :projs, :id => @proj.id, :action => :edit and return
    end

    @terms = @proj.ontology_classes.with_xref_namespace(@proj.ontology_namespace).with_obo_label.ordered_by_xref 
    render :file => 'ontology/obo/show_OBO_file', :use_full_path => true, :layout => false and return
  end

  def class_depictions
    rdf = Ontology::Mx2owl.class_depictions(@proj)
    render(:text => rdf, :type => 'application/rdf+xml')
  end

end
