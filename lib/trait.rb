module Trait

  def self.trait_otu_name(ref = nil, taxon_name = nil, ce = nil)
    ref_txt = ref.nil? ? 'Reference Not Provided' : ref.authors_year
    tn_txt = taxon_name.nil? ? 'Taxon Name Not Provided' : taxon_name.cached_display_name.html_safe
    # TODO: fix me
    ce_txt = ce.nil? ? 'Study/Population Not Provided' : Trait.trait_ce_name(ce)
    s = [ref_txt, tn_txt, ce_txt].join(" : ").html_safe
    s.truncate(254)
  end

  def self.trait_ce_name(ce)
   s = [ ce.geography, ce.sd_y, ce.ed_y, ce.population ].compact.join(":")
   s 
  end

end
