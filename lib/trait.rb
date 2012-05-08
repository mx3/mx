module Trait

  def self.trait_otu_name(ref = nil, taxon_name = nil, ce = nil)
    ref_txt = ref.nil? ? 'NoRef' : ref.authors_year.gsub(/[ ,.]/, '')
    tn_txt = taxon_name.nil? ? 'NoSpecies' : taxon_name.cached_display_name.html_safe
    # TODO: fix me
    ce_txt = ce.nil? ? 'NoStudy' : Trait.trait_ce_name(ce)
    s = [tn_txt, ref_txt, ce_txt].join("_").html_safe
    s.truncate(254)
  end

  def self.trait_ce_name(ce)
   s = [ ce.locality+ce.sd_y+'-'+ce.ed_y, ce.population ].compact.join("_")
   s 
  end

end
