class ExtractsGenesController < ApplicationController

  def popup
    @gene = Gene.find(params[:gene_id])
    @extract = Extract.find(params[:extract_id])
   
    @extract_gene = ExtractsGene.find(:first, :conditions => {:gene_id => @gene.id, :extract_id => @extract.id}, :include => :confidence)
    @confidence = @extract_gene ? @extract_gene.confidence : nil

   # works
    respond_to do |format|
      format.html {} # default .rhtml
      format.js { 
        render :update do |page|
        page.visual_effect :fade, "status_link_#{@gene.id}_#{@extract.id}"
        page.insert_html :bottom, "status_#{@gene.id}_#{@extract.id}", :partial => 'extracts_gene/popup', :locals => {:confidences => @proj.confidences.by_namespace('gene_extract_status'), :gene => @gene, :extract => @extract, :confidence => @confidence}
        end
      }
    end
  end

  def apply_from_popup
    @gene = Gene.find(params[:gene_id]) 
    @extract = Extract.find(params[:extract_id])

    if params[:confidence][:id] == '-1'
      if eg = ExtractsGene.find(:first, :conditions => {:gene_id => @gene.id, :extract_id => @extract.id})
        eg.destroy
      end
    else
      if @extract_gene = ExtractsGene.find(:first, :conditions => {:gene_id => @gene.id, :extract_id => @extract.id})
       @extract_gene.update_attributes(:confidence_id => params[:confidence][:id])
      else
        @extract_gene = ExtractsGene.create!(:gene => @gene, :extract => @extract, :confidence_id => params[:confidence][:id])
      end     
    end

    render :update do |page|
        page.visual_effect :appear, "status_link_#{@gene.id}_#{@extract.id}" # unhide the link
        page.replace "status_#{@gene.id}_#{@extract.id}", :partial => "extracts_gene/status_link", :locals => { :gene => @gene, :extract => @extract, :status => (@extract_gene ? @extract_gene.confidence.display_name(:type => :short) : 'status')}  
        page.visual_effect :fade, "status_popup_#{@gene.id}_#{@extract.id}"  
        page.delay(0.25) do # need a delay so top effect works?
        page.remove "status_popup_#{@gene.id}_#{@extract.id}"  # and get rid of the popup
      end 
    end
  end



end
