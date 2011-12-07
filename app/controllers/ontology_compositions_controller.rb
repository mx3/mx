class OntologyCompositionsController < ApplicationController
  
  def new
    html_id_to_replace = params[:role]
    render :update do |page|
      page.replace_html html_id_to_replace, :partial => "edit", :locals => {:role => params[:role]}
    end
  end
  
end
