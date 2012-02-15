class OntologyRelationshipsController < ApplicationController

  def new
    @ontology_relationship = OntologyRelationship.new(params[:ontology_relationship])
    respond_to do |format|
      format.html {} # default .rhtml
    end
  end

  def create
    @ontology_relationship = OntologyRelationship.new(params[:ontology_relationship])
    @ontology_class = @ontology_relationship.ontology_class1
    @success =  @ontology_relationship.save
    respond_to do |format|
      format.js { }
    end
  end


  def destroy
    @ontology_relationship = OntologyRelationship.find(params[:id])
    @ontology_class = @ontology_relationship.ontology_class1

    @success =  @ontology_relationship.destroy
    if @success
      notice "Destroyed ontology relationship"
    else
      notice "Failed to destroy ontology relationship"
    end

    respond_to do |format|
      format.js { render :action => :create }
    end
  end
end
