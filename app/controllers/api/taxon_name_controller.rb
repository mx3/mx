
class Api::TaxonNameController < ApplicationController

  def index
    redirect_to "http://#{HELP_WIKI}/index.php/App/API/TaxonName" and return
  end

  def show
    redirect_to :action => :index
  end

# # http://127.0.0.1:3000/projects/32/api/ontology/ontology_class/HAO_0001353
# def ontology_class
#   if id = OntologyMethods.xref_from_params(params[:id])
#     if @ontology_class = OntologyClass.find(:first, :conditions => {:proj_id => @proj.id, :xref => id})
#       respond_to do |format|
#         format.html { redirect_to :action => :show_expanded, :id => @ontology_class.id, :controller => '/public/ontology_class'}
#         format.json {
#           render :json => @ontology_class.ontology_class_as_json, :content_type => "text/html" # application/json <- firefox downloads as file
#         }
#       end
#     else 
#       render :file => "#{Rails.root}/public/404.html", :status => :not_found and return # record not found
#     end
#   else
#     render :file => "#{Rails.root}/public/400.html", :status => :bad_request and return
#   end
# end

# def analyze
#   # sanitize!
#   if @result = OntologyMethods::analysis_as_json(:text => params[:id],:proj_id => @proj.id)
#     render :json => @result
#   else
#     render :file => "#{Rails.root}/public/404.html", :status => :not_found and return
#   end
# end

# def label 
#   if @label = Label.find(:first, :conditions => {:proj_id => @proj.id, :name => params[:id]})
#     render :json => @label.as_json
#   else
#     render :file => "#{Rails.root}/public/404.html", :status => :not_found and return
#   end
# end

# def uri_markup
#   # sanitize!
#   if @result = OntologyMethods::markup_as_json(:text => params[:id],:proj_id => @proj.id, :mode => 'bioportal_uri_link')
#     render :json => @result
#   else
#     render :file => "#{Rails.root}/public/404.html", :status => :not_found and return
#   end
# end

# def glossary_markup
#   # sanitize!
#   if @result = OntologyMethods::markup_as_json(:text => params[:id],:proj_id => @proj.id, :mode => 'api_link')
#     render :json => @result
#   else
#     render :file => "#{Rails.root}/public/404.html", :status => :not_found and return
#   end
# end

# def svg 
#   if id = OntologyMethods.xref_from_params(params[:id])
#     if @ontology_class = OntologyClass.find(:first, :conditions => {:proj_id => @proj.id, :xref => id})
#       respond_to do |format|
#         format.html {
#           render :file => "#{Rails.root}/public/400.html", :status => :bad_request and return
#         }
#         format.json {
#           render :json => @ontology_class.svg_as_json, :content_type => "text/html"
#         }
#       end
#     else 
#       render :file => "#{Rails.root}/public/404.html", :status => :not_found and return # record not found
#     end
#   else
#     render :file => "#{Rails.root}/public/400.html", :status => :bad_request and return
#   end

# end

end
