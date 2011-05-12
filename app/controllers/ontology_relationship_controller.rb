class OntologyRelationshipController < ApplicationController

  verify :method => :post, :only => [ :destroy, :create ],
  :redirect_to => { :action => :list }

  def new
    @ontology_relationship = OntologyRelationship.new(params[:ontology_relationship])
    respond_to do |format|
      format.html {} # default .rhtml
      format.js { 
        render :update do |page|
          page.insert_html :bottom, params[:div_id], :partial => 'ontology_relationship/popup_form'
        end
      }
    end
  end

  def create
    @ontology_relationship = OntologyRelationship.new(params[:ontology_relationship])  
    if @ontology_relationship.save
      respond_to do |format|
        format.html {redirect_to :action => :show, :id => @ontology_relationship}  # can't hit this yet in views 
        format.js { 
          render :update do |page|
            page[:ontology_relationship_to_close].remove

            page << "if($('ontology_relationships_for_ontology_class_#{@ontology_relationship.ontology_class1.id}')) {"   # have a ontology_relationship list on the page?
            page.insert_html :bottom, "ontology_relationships_for_ontology_class_#{@ontology_relationship.ontology_class1.id}", :partial => '/ontology_relationship/r', :object => @ontology_relationship, :locals => {:matching_id => @ontology_relationship.ontology_class1.id}
            page << "}"
            
            page << "if($('intersection_relationships_for_ontology_class_#{@ontology_relationship.ontology_class1.id}')) {"   # have a ontology_relationship intersections list on the page?
            page.insert_html :bottom, "intersection_relationships_for_ontology_class_#{@ontology_relationship.ontology_class1.id}", :partial => '/ontology_relationship/r', :object => @ontology_relationship, :locals => {:matching_id => @ontology_relationship.ontology_class1.id}
            page << "}"

            # TODO: javascript increment the total
          end
        }
      end
    else
      respond_to do |format|
        format.html {} # can't hit this yet in views 
        format.js { 
          render :update do |page|
            page.visual_effect :shake, "ontology_relationship_to_close" 
          end
        }
      end
    end
  end


  def destroy
    @ontology_relationship = OntologyRelationship.find(params[:id])
    if @ontology_relationship.destroy
      respond_to do |format|
        format.html {
          flash[:notice] = "Destroyed ontology relationship."
          redirect_to :action => :index, :controller => :ontology
          } # can't hit this yet in views 
          format.js { 
            render :update do |page|
              page["ontology_relationship_in_list_#{params[:id]}"].remove
              # TODO: javascript decrement the total
            end
          }
        end
    else
      respond_to do |format|
        format.html {
          flash[:notice] = "Failed to destroyed ontology relationship."
          redirect_to :back
          } # can't hit this yet in views 
          format.js { 
            render :update do |page|
              page["ontology_relationship_in_list_#{params[:id]}"].shake
            end
          }
        end
      end
    end

end