class CodingsController < ApplicationController

  def index
    redirect_to :action => :index, :controller => :chrs
  end

  def show
    c = Coding.find(params[:id])
    redirect_to :action => :show_codings, :controller => :otus, :id => c.otu_id
  end

  def coding_details
    respond_to do |wants|
      wants.html {}
    end
  end

  def owl_export
    graph = RDF::Graph.new
    owl = OWL::OWLDataFactory.new(graph)
    otus = Otu.find(:all, :conditions => "(proj_id = #{@proj.id})")
    otus.each do |otu|
      Ontology::Mx2owl.translate_otu(otu, owl)
    end
    all_codings = Coding.find(:all, :conditions => "(proj_id = #{@proj.id})")
    all_codings.each do |coding|
      Ontology::Mx2owl.translate_coding(coding, owl)
    end
    chrs = @proj.chrs
    chrs.each do |chr|
      Ontology::Mx2owl.translate_chr(chr, owl)
    end
    rdf = RDF::Writer.for(:ntriples).buffer {|writer| writer << graph }
    # when rdfxml gem is updated with bugfix (or we move to ruby 1.9) we can switch to next line
    #rdf = RDF::RDFXML::Writer.buffer {|writer| writer << graph }
    render(:text => (rdf))
  end

end
