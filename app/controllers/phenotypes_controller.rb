class PhenotypesController < ApplicationController
  
  def new
    @chr_state = ChrState.find(params[:chr_state])
  end
  
  def new_concrete_phenotype
    @chr_state = ChrState.find(params[:chr_state])
    phenotype_class = Phenotype.kinds[params[:phenotype][:kind]]
    @phenotype = phenotype_class.constantize.new
    @chr_state.phenotype = @phenotype
    render :update do |page|
      page[:choose_phenotype_kind_form].remove
      partial = "edit_" + phenotype_class.to_s.underscore
      page.insert_html :bottom, :phenotype_form_area, :partial => partial
    end  
  end
  
  def update_qualitative_phenotype
    chr_state = ChrState.find(params[:chr_state])
    if (params[:save])
      phenotype = QualitativePhenotype.new
      phenotype.entity = find_term_from_params(params, "entity")
      phenotype.quality = find_term_from_params(params, "quality")
      phenotype.dependent_entity = find_term_from_params(params, "dependent_entity") if !params[:dependent_entity_hidden_id].blank? 
      phenotype.save
      chr_state.phenotype = phenotype
      chr_state.save
    end
    redirect_to :controller => :chrs, :action => :show, :id => chr_state.chr
  end
  
  def update_presence_absence_phenotype
    chr_state = ChrState.find(params[:chr_state])
    if (params[:save])
      phenotype = PresenceAbsencePhenotype.new
      phenotype.entity = find_term_from_params(params, "entity")
      phenotype.is_present = params[:is_present_hidden]
      phenotype.within_entity = find_term_from_params(params, "within_entity") if !params[:within_entity_hidden_id].blank? 
      phenotype.save
      chr_state.phenotype = phenotype
      chr_state.save
    end
    redirect_to :controller => :chrs, :action => :show, :id => chr_state.chr
  end
  
  def update_count_phenotype
    chr_state = ChrState.find(params[:chr_state])
    if (params[:save])
      phenotype = CountPhenotype.new
      phenotype.entity = find_term_from_params(params, "entity")
      phenotype.minimum = params[:minimum_hidden]
      phenotype.maximum = params[:maximum_hidden]
      phenotype.within_entity = find_term_from_params(params, "within_entity") if !params[:within_entity_hidden_id].blank? 
      phenotype.save
      chr_state.phenotype = phenotype
      chr_state.save
    end
    redirect_to :controller => :chrs, :action => :show, :id => chr_state.chr
  end
  
  def update_relative_phenotype
    chr_state = ChrState.find(params[:chr_state])
    if (params[:save])
      phenotype = RelativePhenotype.new
      phenotype.entity = find_term_from_params(params, "entity")
      phenotype.quality = find_term_from_params(params, "quality")
      phenotype.relative_entity = find_term_from_params(params, "relative_entity")
      phenotype.relative_quality = find_term_from_params(params, "relative_quality")
      phenotype.relative_magnitude = params[:relative_magnitude_hidden]
      phenotype.relative_proportion = params[:relative_proportion_hidden] if !params[:relative_proportion_hidden].blank?
      phenotype.save
      chr_state.phenotype = phenotype
      chr_state.save
    end
    redirect_to :controller => :chrs, :action => :show, :id => chr_state.chr
  end
  
  def edit
    if params[:id]
      @phenotype = Phenotype.find(params[:id])
      @chr_state = @phenotype.chr_state
    else
      redirect_to :action => :new, :chr_state => params[:chr_state]
    end
  end
  
  def new_term
    html_id_to_replace = params[:role]
    render :update do |page|
      page.replace_html html_id_to_replace, :partial => "edit_ontology_term", :locals => {:role => params[:role], :pc_edit_area => params[:pc_edit_area], :pc_level_id => params[:pc_level_id]}
    end
  end
  
  def create_term
    term_id = params[params[:role] + "_bioportal_full_id"]
    term = OntologyTerm.find_or_create_by_uri(term_id)
    term.label = params[params[:role] + "_bioportal_preferred_name"]
    term.bioportal_ontology_identifier = params[params[:role] + "_bioportal_ontology_id"]
    term.save
    render :update do |page|
      page.replace_html params[:role], :partial => "show_ontology_value", :locals => {:term => term, :role => params[:role], :pc_edit_area => params[:pc_edit_area], :pc_level_id => params[:pc_level_id]}
      page.replace params[:role] + "_hidden_id", hidden_field_tag(params[:role] + "_hidden_id", term.id)
      page.replace params[:role] + "_hidden_class", hidden_field_tag(params[:role] + "_hidden_class", term.class)
    end
  end
  
  def create_composition
    composition = OntologyComposition.new
    pc_level_id = params[:pc_level_id]
    genus_id = params["genus#{pc_level_id}_hidden_id"]
    genus = OntologyTerm.find(genus_id)
    composition.genus = genus
    differentiae_keys = params["differentiae_inputs" + pc_level_id].split(",")
    differentiae_keys.each do |diff_key|
      uuid = diff_key.sub("differentia-", "")
      class_id = params["differentia_class-#{uuid}_hidden_id"]
      class_class = params["differentia_class-#{uuid}_hidden_class"]
      differentia_value = class_class.constantize.find(class_id)
      differentia = Differentia.new
      differentia.value = differentia_value
      property_id = params["differentia_property-" + uuid]
      property = OntologyTerm.find(property_id)
      differentia.property = property
      differentia.save
      composition.differentiae << differentia
    end
    composition.save
    render :update do |page|
      page.remove pc_level_id
      page.replace_html params[:role], :partial => "show_ontology_value", :locals => {:term => composition, :pc_edit_area => params[:pc_edit_area], :pc_level_id => params[:pc_level_id], :role => params[:role]}
      page.replace params[:role] + "_hidden_id", hidden_field_tag(params[:role] + "_hidden_id", composition.id)
      page.replace params[:role] + "_hidden_class", hidden_field_tag(params[:role] + "_hidden_class", composition.class)
    end
  end
  
  def new_differentia
    differentia = Differentia.new
    render :update do |page|
      page.insert_html :bottom, params[:differentiae_id], :partial => "differentia", :locals => {:differentia => differentia, :pc_edit_area => params[:pc_edit_area], :pc_level_id => params[:pc_level_id]}
    end
 	 
  end
  
  def remove_ontology_value
    render :update do |page|
      page.replace_html params[:role], :partial => "show_ontology_value", :locals => {:term => nil, :role => params[:role], :pc_edit_area => params[:pc_edit_area], :pc_level_id => params[:pc_level_id]}
      page.replace params[:role] + "_hidden_id", hidden_field_tag(params[:role] + "_hidden_id", nil)
      page.replace params[:role] + "_hidden_class", hidden_field_tag(params[:role] + "_hidden_class", nil)
    end
  end
  
  private
  
  def find_term_from_params(params, role)
    params[role+"_hidden_class"].constantize.find(params[role+"_hidden_id"])
  end
  
end
