# encoding: utf-8
module TaxonNameHelper

  # for indented lists and such
  def rank_n(rank)
    TaxonName::ICZN_RANKS.include?(rank) ? TaxonName::ICZN_RANKS.size - TaxonName::ICZN_RANKS.index(rank) : 0    
  end

  # takes a TaxonName
  def taxon_name_with_linked_author_year(taxon_name)
    if taxon_name.ref.blank?
      taxon_name.display_name(:type => :name_with_author_year)
    else
      (taxon_name.display_name + " " + link_to(taxon_name.display_author_year, :action => :show, :controller => :refs, :id => taxon_name.ref_id))
    end
  end

  def report_headers # :yields: Array of headers
   # must match columns in report_data, see below, seperated for display purposes
       [ 'mx id',
         'name',
         'original combination',
         'valid name',
         'status',
         'original spelling',
         'agreement spelling',
         'original genus',
         'original subgenus',
         'original species',
         'iczn group',
         'classification',
         'reference',
         'page validated on',
         'page first appearance',
         'notes'
       ]
  end

  def report_data(taxon_name) # :yields: Array of Strings
    # must match report_headers, see above
      t = taxon_name
      [ t.id,
        t.name,
        t.display_name(:type => :original_combination),
        (t.valid_name ? t.valid_name.display_name(:type => :name_with_author_year) : '-'),
        (t.status ? t.status.display_name : 'valid'),
        (t.original_spelling.blank? ? '-' : t.original_spelling),
        (t.agreement_name.blank? ? '-' : t.agreement_name),
        (t.original_genus ? t.original_genus.display_name : '-'),
        (t.original_subgenus ? t.original_subgenus : '-'),
        (t.original_species ? t.original_species : '-'),
        t.iczn_group,
        (t.parent ? t.parent.name : '-'),
        (t.ref ? t.ref.display_name : 'na'),
        (t.page_validated_on ? t.page_validated_on : '-'),
        (t.page_first_appearance ? t.page_first_appearance : '-'),
        (t.notes.blank? ? '-' : t.notes.gsub(/\n/,''))
      ]
  end

end
