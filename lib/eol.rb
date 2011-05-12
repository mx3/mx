# encoding: utf-8
module Eol
  EOL_RANKS = [ 'Family', 'Genus'] # 'Kingdom', 'Phylum', 'Class', 'Order' - mx doesn't track non-governed names so we never provide these elements

  EOL_SYNONYMY_STATUS = [    
                      "ambiguous synonym",
                      "anamorph",
                      "basionym",
                      "heterotypic synonym",
                      "homotypic synonym",
                      "junior synonym",
                      "misapplied name",
                      "nomenclatural synonym",
                      "objective synonym",
                      "senior synonym",
                      "subjective synonym",
                      "synonym",
                      "teleomorph",
                      "unavailable name",
                      "valid name"
                      ]

  def self.eol_xml(options = {})
    opt = {
      :target => '',
      :otus => []        # mx Otus
    }.merge!(options)

    xml = Builder::XmlMarkup.new(:target => opt[:target], :indent => 2)
  
    xml.instruct! :xml, :version => '1.0'
    xml.response("xmlns" => "http://www.eol.org/transfer/content/0.2",
      "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
      "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
      "xmlns:dcterms" => "http://purl.org/dc/terms/",
      "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
      "xmlns:dwc" => "http://rs.tdwg.org/dwc/dwcore/",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation" => "http://www.eol.org/transfer/content/0.2 http://services.eol.org/schema/content_0_2.xsd") {

      opt[:otus].each do |o|

        contents = o.contents.by_eol_legal_content_type.that_are_published

        if contents.size > 0
          xml.taxon do
            Eol.taxon_related_elements(:taxon_name => o.taxon_name, :target => opt[:target])        

            contents.each do |c|
              Eol.text_data_object_element(:content => c, :target => opt[:target])      
              c.figures.not_using_morphbank_images.with_licensed_images.each do |f|  # TODO: add "with valid license"
                Eol.image_data_object_element(:figure => f, :target => opt[:target])      
              end
            end
          end
        end

      end
    }

    return opt[:target]
  end

  def self.taxon_related_elements(options = {})
    opt = {
      :target => '',
      :taxon_name => nil  # a TaxonName instance
    }.merge!(options)

    t = opt[:taxon_name]
    return nil if !t

    xml = Builder::XmlMarkup.new(:target => opt[:target], :indent => 2)
      
      xml.dc(:identifier,  "http:/#{HOME_SERVER}/api/taxon_name/show/#{t.id}")
      xml.dc(:source,  "http:/#{HOME_SERVER}/api/taxon_name/show/#{t.id}")

      EOL_RANKS.each do |r|
        xml.dwc(r.to_sym, t.name_at_rank(r.downcase) ) if t.name_at_rank(r.downcase)
      end

      xml.dwc(:ScientificName, t.display_name(:type => :string_no_author_year))
    
      t.synonyms.each do |s|
        xml.synonym(s.display_name(:type => :string_no_author_year), :relationship =>  Eol::EOL_SYNONYMY_STATUS.include?(s.status) ? s.status : 'synonym')
      end

      # TODO: are we using this correctly, or is this for the time when this code was called/resource generated
      xml.dcterms(:created, t.created_on)
      xml.dcterms(:modified, t.updated_on)

      if t.ref 
        xml.reference(t.ref.display_name)
      elsif !t.display_author_year.blank?
        xml.reference(t.display_author_year)
      end

    return opt[:target]
  end
     
  private

  def self.text_data_object_element(options = {})
    opt = {
      :target => '',
      :content => nil      # an mx Content object 
    }.merge!(options)

    c = opt[:content]
    return nil if c.nil?
    raise if c.content_type.subject.blank? 

    xml = Builder::XmlMarkup.new(:target => opt[:target], :indent => 2)

    xml.dataObject do

      xml.dc(:identifier, "http:/#{HOME_SERVER}/api/content/#{c.id}")
      xml.dataType('http://purl.org/dc/dcmitype/Text')
      xml.mimeType('text/html')

      xml.dcterms(:created, c.created_on)
      xml.dcterms(:modified, c.updated_on)
      xml.dc(:title, c.content_type.display_name, 'xml:lang' => 'en') 
      xml.dc(:language, 'en')

      xml.license(c.attribution_license_uri) # c.proj.default_license
      
      # underscore to dash, slashes "by_nc_sa_3_0"
      # TODO: limit license options
      # http://creativecommons.org/licenses/(publicdomain|by|by-nc|by-sa|by-nc-sa)(/[0-9]\.[0-9])?/

      xml.dcterms(:rightsHolder, c.attribution_rights_holder)

      xml.audience('General public')
      xml.audience('Expert users')

      xml.dc(:source, "http:/#{HOME_SERVER}/api/content/#{c.id}")
      xml.subject("http://rs.tdwg.org/ontology/voc/SPMInfoItems#" + c.content_type.subject.gsub(/\s/,''))
      xml.dc(:description, c.text, 'xml:lang' => 'en')
    end

    return opt[:target]
  end

  def self.image_data_object_element(options = {})
    opt = {
      :target => '',
      :figure => nil,                  # an mx Image 
      :data_type => "mx",              # required <<<- remove?!
      :title => "No title provided.",  # pass a scientificName typically
      :project => nil,
    }.merge!(options)

    f = opt[:figure]

    return nil if f.nil?

    xml = Builder::XmlMarkup.new(:target => opt[:target], :indent => 2)

    xml.dataObject do

      xml.dc(:identifier,  "http:/#{HOME_SERVER}/api/figure/show/#{f.id}")

      xml.dataType('http://purl.org/dc/dcmitype/StillImage')
      xml.mimeType('image/jpeg')

      xml.agent((f.image.contributor.blank? ? f.image.creator.full_name :  f.image.contributor  ), :role => 'compiler') 
      xml.agent((f.image.maker.blank? ? f.image.creator.full_name :  f.image.maker), :role => 'creator') 
      xml.agent((opt[:project].nil? ? f.proj.name : opt[:project]), :role => 'project')

      xml.dcterms(:created, f.created_on)
      xml.dcterms(:modified, f.updated_on)

      xml.dc(:title, opt[:title]) 
      
      xml.license( CONTENT_LICENSES[f.image.license][:uri] )  
      xml.dcterms(:rightsHolder, f.image.copyright_holder)

      if f.image.ref
        xml.dcterms(:bibliographicCitation, f.image.ref.display_name)
      end

      xml.dc(:source, "http:/#{HOME_SERVER}/api/figure/show/#{f.id}")

      # TODO: Redirect to Morphbank images when MB images are allowed

      xml.mediaURL('http://' + HOME_SERVER + f.image.path_for(:size => :medium, :context => :web))
      xml.thumbnailURL('http://' + HOME_SERVER + f.image.path_for(:size => :thumb, :context => :web))

      # TODO: location and geo:Point can come from specimens ultimately

    end

    return opt[:target]
  end

end
