# encoding: utf-8
module SeqHelper

  def seq_source_otus_tag(seq)
    seq.bound_otus.collect{|o| o.display_name(:type => :list)}.join(';').html_safe
  end

  def display_seq_tag(seq)
    cs = seq.sequence.andand.clone
    cs ||= ""
    s = ''
    return ('no nucleotides added yet ' + (seq.status? ? '(' + content_tag(:i,  seq.status) + ')' : '') ) if !cs || cs.length == 0
    while cs.length > 0
      s << cs.slice!(0..80) + '<br />'     
    end
    s.html_safe
  end

   def display_protein_tag(options = {})
    opt = {
      :seq_obj => '',
      :codon_table => 1,
      :frame => 1
    }.merge!(options) 
    nucs = Bio::Sequence::NA.new(opt[:seq_obj].sequence)
    prot = nucs.translate(opt[:frame], opt[:codon_table])
    return ('no nucleotides added yet ' + (opt[:seq_obj].status? ? '(' + content_tag(:i,  opt[:seq_obj].status) + ')' : '') ) if prot.length == 0
    s = ''
    while prot.length > 0
      s << prot.slice!(0..80) + '<br />'     
    end
    s.html_safe
  end

  def seq_source_genes_tag(seq)
  if !seq.gene && seq.pcr.blank?
      content_tag :em, 'none'
    elsif !seq.pcr.blank?
      [seq.pcr.fwd_primer.gene_name, seq.pcr.rev_primer.gene_name].uniq.join(" / ")
    elsif !seq.gene.blank?
      seq.gene.name 
    else 
      content_tag :em, 'data error', :style => 'color:red'
    end
  end

  # note the following two methods are kludge at present, and based on the restriction of one otu/seq/gen
  # which is now not true as all that is required is gene and or specimen or otu
  # can modify to pass obj, then detect class and search as such, also needs multiple results if found
 
  # def seq_from_specimen_gene(specimen_id, gene_id)
  #  Seq.find(:first, :conditions => ["(specimen_id = (?)) and (gene_id = (?)) and (proj_id = (?))", specimen_id, gene_id, @proj.id])
  # end
  
  # TODO: Deprecate for Otu.sequences
  # def seq_from_otu_gene(otu_id, gene_id)
  #  Seq.find(:first, :conditions => ["(otu_id = (?)) and (gene_id = (?)) and (proj_id = (?))", otu_id, gene_id, @proj.id])
  # end

  # TODO: enhance the simple integer count 
  def seq_cell_status(otu, gene) # :yields: HTML cell representation of this gene/OTU combination results 
    # want 'done', 'data not done', 'add', with links to show seq 

      if seqs = otu.sequences(:gene_ids => [gene.id]) 
        
        if seqs.size == 0
          return content_tag(:td, 0)
        else
          return content_tag(:td, seqs.size)
        end

      else 
        return content_tag(:td,  link_to('add', {:controller => :seqs, :action => "new_from_table", :otu_id => otu_id, :gene_id => gene_id  }), :class => "no_decision")
      end

      #rescue 
      # return "error: " + otu_id.to_s + " " + gene_id.to_s + " " + @proj.id.to_s     
      #end

  end
end
