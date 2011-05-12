# encoding: utf-8
module ExtractsGeneHelper

 def gene_extract_status_link(extract, gene)
    extracts_gene = ExtractsGene.find(:first, :conditions => {:extract_id => extract.id, :gene_id => gene.id})
    render(:partial => "extracts_gene/status_link", :locals => {:gene => gene, :extract => extract, :status => (extracts_gene ? extracts_gene.display_name(:type => :status) : 'status')}  )
 end

 def gene_extract_status(extract, gene)
    if extracts_gene = ExtractsGene.find(:first, :conditions => {:extract_id => extract.id, :gene_id => gene.id})
      extracts_gene.confidence.short_name
    else
      '-'
    end
 end

end
