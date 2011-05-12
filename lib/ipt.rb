# encoding: utf-8
module Ipt

 # see
 # http://rs.tdwg.org/dwc/terms/history/versions/index.htm
 # http://rs.tdwg.org/dwc/terms/history/index.htm
 # http://code.google.com/p/gbif-providertoolkit/wiki/IPT2ManualNotes?tm=6
 # http://code.google.com/p/darwincore/wiki/Occurrence
 # http://rs.tdwg.org/dwc/terms/history/versions/index.htm#dwcdraft14 

  class IptOccurance
    attr_reader :obj, :proj, :ce, :taxon_name, :otu, :identifier
    COLS = [  
      :occurrence_id, 
      :modified,
      :basis_of_record,
      :institution_code, 
      :collection_code,
      :information_withheld, 
      :occurrence_remarks,
      :scientific_name, 
      :parent_name_usage,
      :kingdom, 
      :phylum, 
      :tn_class,                     # class is reserved
      :tn_order,                     # order is reserved
      :family, 
      :genus,
      :specific_epithet, 
      :taxon_rank,
      :infraspecific_epithet, 
      :scientific_name_authorship,
      :nomenclatural_code, 
      :identification_qualifier,
      :higher_geography,	
      :continent, 
      :water_body,
      :island_group,	
      :island, 
      :country, 
      :state_province,	
      :county, 
      :locality, 
      :minimum_elevation_in_meters, 
      :maximum_elevation_in_meters,
      :minimum_depth_in_meters,
      :maximum_depth_in_meters, 
      :sampling_protocol,
      :establishment_means,
      :event_date,
      :start_day_of_year,
      :recorded_by,
      :sex, 
      :life_stage,
      :dynamic_properties,                 
      :associated_media,
      :occurrence_details,
      :catalog_number,              	     # Darwin Core 1.4 Curatorial extension
      :identified_by, 	
      :date_identified, 
      :record_number,
      :field_number, 
      :field_notes, 
      :verbatim_event_date,
      :verbatim_elevation,
      :verbatim_depth, 
      :preparations, 
      :type_status, 
      :associated_sequences,
      :other_catalog_numbers, 
      :associated_occurrences,
      :disposition, 	
      :individual_count, 
      :decimal_latitude, 	                # Darwin Core 1.4 Geospatial Element
      :decimal_longitude, 
      :geodetic_datum, 	
      :coordinate_uncertainty_in_meters,
      :point_radius_spatial_fit, 	
      :verbatim_coordinates, 
      :verbatim_latitude, 	
      :verbatim_longitude, 
      :verbatim_coordinate_system, 
      :georeference_protocol, 	
      :georeference_sources, 
      :georeference_verification_status,
      :georeference_remarks, 
      :footprint_WKT, 	
      :footprint_spatial_fit,
      :year,                           # Misc DC (not necessarily 1.4)
      :month,
      :day,
      :proj_id,                        # mx housekeeping
      :specimen_id,
      :lot_id, 
      :ce_id,
      :ce_geog_id,
      :otu_id,
      :taxon_name_id
    ]

    def initialize(obj)
      # Keep other checking outside of initialize
      return false if (obj.class != Specimen) && (obj.class != Lot) && !obj.is_public
      @obj = obj
      @ce = get_ce 
      return false if !@ce.andand.is_public  
      @proj = obj.proj
      @otu = get_otu
      @taxon_name = @otu.andand.taxon_name 
      @identifier = get_identifier
      true
    end

    def ipt_record
      # Keep this test here rather than initialize because we might ultimately drop these checks
      return false if @ce.nil? || @taxon_name.nil? 
      IptRecord.new( COLS.inject({}){ |hsh, k| hsh.merge!(k => self.send(k) ) } )
    end

    # This should only be called from individual specimen records (within application).
    # To serialize groups of specimens see Batch. Deletes current record if found.
    def serialize
      begin 
        ActiveRecord::Base.transaction do  
          o = "#{@obj.class.name.downcase}_id".to_sym
          if r = IptRecord.find(:first, :conditions => {o => @obj.id }) 
            r.destroy 
          end
          if i = self.ipt_record
            i.save!
          else
            return false
          end
        end
      rescue
        return false 
      end 
      true
    end

    #= Methods to map mx to the various DC standards. Method names must occur in COLS. 

    private

    #== Darwin Core 1.4 (Draft Standard)

    def occurrence_id 
      # An identifier for the Occurrence (as opposed to a particular digital record of the occurrence).
      # In the absence of a persistent global unique identifier, construct one from a combination of identifiers in the record that will most closely make the occurrenceID globally unique.
      # For a specimen in the absence of a bona fide global unique identifier, for example, use the form: "urn:catalog:[institutionCode]:[collectionCode]:[catalogNumber].
      # Examples: "urn:lsid:nhm.ku.edu:Herps:32", "urn:catalog:FMNH:Mammal:145732" 

     #if v = @obj.identifiers.that_are_global.andand.first
     #  v.cached_display_name
     #else
      "urn:catalog:#{institution_code}:#{collection_code}:#{catalog_number}"
     #end
    end

    def institution_code
      # The name (or acronym) in use by the institution having custody of the object(s) or information referred to in the record.
      # "MVZ", "FMNH", "AKN-CLO", "University of California Museum of Paleontology (UCMP)" 
      v = @obj.repository.andand.coden
      v ||= @proj.default_institution.andand.coden
      v
    end

    def collection_code
      # The name, acronym, coden, or initialism identifying the collection or data set from which the record was derived.
      # Examples: "Mammals", "Hildebrandt", "eBird".
      # We default to the namespace of the identifier 
      # TODO: this needs more thought probably  
      @identifier ? @identifier.namespace.short_name : @proj.collection_code
    end

    def catalog_number
      #	An identifier (preferably unique) for the record within the data set or collection.
      # Examples: "2008.1334", "145732a", "145732". 
      @identifier ?  @identifier.identifier : @obj.id.to_s
    end

    def information_withheld
      # Additional information that exists, but that has not been shared in the given record.
      # Examples: "location information not given for endangered species", "collector identities withheld", "ask about tissue samples".
      nil # TODO: feature request
    end

    def modified
      # Note this is dublic, not DC!
      # http://dublincore.org/documents/dcmi-terms/#terms-modified
      # TODO: check the sort 
      [@obj.updated_on, @ce.andand.updated_on, @taxon_name.andand.updated_on].compact.sort.first
    end

    def basis_of_record
    'PreservedSpecimen'
    end


    def occurrence_remarks
      # Comments or notes about the Occurrence.
      # Example: "found dead on road". For discussion see http://code.google.com/p/darwincore/wiki/Occurrence
      # I think this matches with specimen/lot notes, it's hard to say.
      @obj.notes
    end

    def scientific_name
      # The full name of lowest level taxon the Cataloged Item can be identified as a member of; includes genus name, specific epithet, and subspecific epithet (zool.) or infraspecific rank abbreviation, and infraspecific epithet (bot.) Use name of suprageneric taxon (e.g., family name) if Cataloged Item cannot be identified to genus, species, or infraspecific taxon.
      @taxon_name.display_name(:type => :string_no_author_year)
    end

    def parent_name_usage
      # The full name, with authorship and date information if known, of the direct, most proximate higher-rank parent taxon (in a classification) of the most specific element of the scientificName.
      # Examples: "Rubiaceae", "Gruiformes", "Testudinae". For discussion see http://code.google.com/p/darwincore/wiki/Taxon
      @taxon_name.parent.display_name(:type => :string_with_author_year)
    end

    def kingdom
      nil # we don't track this
    end

    def phylum
      nil # nor this
    end

    def tn_class
      nil # or this
    end

    def tn_order
      nil # or this
    end

    def family
      @taxon_name.name_at_rank('family') 
    end

    def genus
      @taxon_name.name_at_rank('genus') 
    end

    def specific_epithet
      if @taxon_name.iczn_group == 'species'
        @taxon_name.name
      else
        nil
      end
    end 

    def taxon_rank
      # The taxonomic rank of the most specific name in the scientificName. Recommended best practice is to use a controlled vocabulary.
      # Examples: "subspecies", "varietas", "forma", "species", "genus".
      if (@taxon_name.iczn_group == 'species') && (@taxon_name.rank == 'subspecies')
      'subspecies'
      elsif @taxon_name.iczn_group == 'variety'
      'variety'
      else
      ''
      end
    end

    def infraspecific_epithet
      if @taxon_name.iczn_group == 'species' || @taxon_name.iczn_group == 'species' && @taxon_name.rank == 'subspecies'
     'subspecies'
      elsif @taxon_name.iczn_group == 'variety'
     'variety'
      else
     ''
      end
    end

    def scientific_name_authorship
      @taxon_name.display_author_year
    end

    def nomenclatural_code
      # The nomenclatural code under which the ScientificName is constructed. Examples: "ICBN", "ICZN", "BC", "ICNCP", "BioCode"
    'ICZN' # no support for others at present
    end

    def identification_qualifier
      # A brief phrase or a standard term ("cf.", "aff.") to express the determiner's doubts about the Identification.
      # 	Examples: 1) For the determination "Quercus aff. agrifolia var. oxyadenia", identificationQualifier would be "aff. agrifolia var. oxyadenia" with accompanying values "Quercus" in genus, "agrifolia" in specificEpithet, "oxyadenia" in infraspecificEpithet, and "var." in rank. 2) For the determination "Quercus agrifolia cf. var. oxyadenia", identificationQualifier would be "cf. var. oxyadenia " with accompanying values "Quercus" in genus, "agrifolia" in specificEpithet, "oxyadenia" in infraspecificEpithet, and "var." in rank.
      nil # We don't provide this at a taxon name level, only for OTUs
    end

    def higher_geography
      @ce.andand.geography
    end

    def continent
      return @ce.geog.name if @ce && @ce.geog && (@ce.geog.geog_type == 'continent')
      nil 
    end

    def water_body
      return @ce.geog.name if @ce && @ce.geog && (@ce.geog.geog_type == 'ocean')
      nil 
    end

    def island_group
      return @ce.geog.name if @ce && @ce.geog && (@ce.geog.geog_type == 'island group')
      nil 
    end

    def island
      return @ce.geog.name if @ce && @ce.geog && (@ce.geog.geog_type == 'island')
      nil 
    end

    def country 
      if ce = @ce
        return ce.geog.country.name if ce.geog && ce.geog.country
      end
      nil 
    end

    def state_province
      if ce = @ce
        return ce.geog.state.name if ce.geog && ce.geog.state # catch those properly filled out
        return ce.geog.name if ce.geog && ce.geog.geog_type.name == 'state' || ce.geog && ce.geog.geog_type.name == 'province' # catch those not filled out
      end
      nil 
    end

    def county 
      if ce = @ce
        return ce.geog.county.name if ce.geog && ce.geog.county # catch those properly filled out
        return ce.geog.name if (ce.geog && ce.geog.geog_type.name == 'county') 
      end
      nil 
    end

    def locality
      @ce.andand.locality
    end

    def minimum_elevation_in_meters
      @ce.andand.convert_elevation('min', 'meters').to_s
    end

    def maximum_elevation_in_meters
      @ce.andand.convert_elevation('max', 'meters').to_s
    end

    def minimum_depth_in_meters
      nil # Not handled
    end

    def maximum_depth_in_meters
      nil # Not handled
    end

    def sampling_protocol
      # The name of, reference to, or description of the method or protocol used during an Event. 
      @ce.andand.verbatim_method
    end

    def establishment_means
      # The process by which the biological individual(s) represented in the Occurrence became established at the location. Recommended best practice is to use a controlled vocabulary.
      # Examples: "cultivated", "invasive", "escaped from captivity", "wild", "native". For discussion see http://code.google.com/p/darwincore/wiki/Occurrence
      # TODO: feature request 
      nil
    end

    def event_date
      # The date-time or interval during which an Event occurred. For occurrences, this is the date-time when the event was recorded. Not suitable for a time in a geological context. Recommended best practice is to use an encoding scheme, such as ISO 8601:2004(E).
      # Examples: "1963-03-08T14:07-0600" is 8 Mar 1963 2:07pm in the time zone six hours earlier than UTC, "2009-02-20T08:40Z" is 20 Feb 2009 8:40am UTC, "1809-02-12" is 12 Feb 1809, "1906-06" is Jun 1906, "1971" is just that year, "2007-03-01T13:00:00Z/2008-05-11T15:30:00Z" is the interval between 1 Mar 2007 1pm UTC and 11 May 2008 3:30pm UTC, "2007-11-13/15" is the interval between 13 Nov 2007 and 15 Nov 2007.  
      # TODO: check formating of date range vs. standard?
      @ce.andand.date_range
    end

    def start_day_of_year
      # # ordinal 1-365 if latest/earliest both exist don't populate
      if @ce && !@ce.sd_d.blank? && !@ce.sd_m.blank? && !@ce.sd_y.blank? && (@ce.end_date.length == 0)
          @ce.start_day_of_year 
      else
        nil
      end
    end

    def recorded_by
      @ce.andand.collectors
    end

    def sex
      @obj.sex
    end

    def life_stage
      @obj.stage
    end

    def dynamic_properties  # !! additional elements, in the format "element: value;"
      nil
    end

    def associated_media
      # A list (concatenated and separated) of identifiers (publication, global unique identifier, URI) of media associated with the Occurrence.
      # http://arctos.database.museum/SpecimenImages/UAMObs/Mamm/2/P7291179.JPG
      nil
    end

    def occurrence_details 
      # A reference (publication, URI) to the most detailed information available about the Occurrence.
      # http://mvzarctos.berkeley.edu/guid/MVZ:Mamm:165861
      # TODO: feature request
      nil
    end

    # DC 1.4 Curatorial

    def catalog_number
      @identifier ? @identifier.identifier : @obj.id.to_s
    end

    def identified_by
      # TODO: validate order
      if @obj.class == Specimen
        @obj.specimen_determinations.first.identified_by
      end 
    end

    def date_identified
      if @obj.class == Specimen
        @obj.specimen_determinations.first.det_on.year
      else
        nil
      end 
    end

    def record_number
      # An identifier given to the Occurrence at the time it was recorded. Often serves as a link between field notes and an Occurrence record, such as a specimen collector's number.
      # TODO: feature request - A identifier type?  There is no way to distinguish these in mx at present.
      nil
    end

    def field_number
      @ce.andand.display_name(:type => :trip_code)
    end

    def field_notes
      # One of a) an indicator of the existence of, b) a reference to (publication, URI), or c) the text of notes taken in the field about the Event.
      # Example: "notes available in Grinnell-Miller Library".
      # TODO: feature request
      nil 
    end

    def verbatim_event_date 
      nil # technically we parse, but the parsing allows roman ... hmm 
    end

    def verbatim_elevation
      nil # technically we parse
    end

    def verbatim_depth
      nil
    end

    def preparations
      @obj.preparation.andand.display_name 
    end

    def type_status
      if @obj.class == Specimen
        @obj.type_assignments.collect{|ta| ta.display_name}.join("; ")
      else
        nil
      end
    end

    def associated_sequences 
      # A list (concatenated and separated) of identifiers (publication, global unique identifier, URI) of genetic sequence information associated with the Occurrence. "GenBank: U34853.1". 
      if @obj.class == Specimen
        # TODO: feature request - extend to sequence.identifiers
        @obj.sequences.collect{|s| s.genbank_identifier}.compact.uniq.join("; ") 
      else 
        nil
      end
    end

    def other_catalog_numbers
      # A list (concatenated and separated) of previous or alternate fully qualified catalog numbers or other human-used identifiers for the same Occurrence, whether in the current or any other data set or collection.
      # FMNH:Mammal:1234", "NPS YELLO6778; MBG 3342
      @obj.identifiers.collect{|i| i.cached_display_name}.join("; ")
    end

    def associated_occurrences 
      # A list (concatenated and separated) of identifiers of other Occurrence records and their associations to this Occurrence.
      # "sibling of FMNH:Mammal:1234; sibling of FMNH:Mammal:1235"
      # TODO: use associations 
      nil
    end

    def disposition
      # The current state of a specimen with respect to the collection identified in collectionCode or collectionID. Recommended best practice is to use a controlled vocabulary. 
      # "in collection", "missing", "voucher elsewhere", "duplicates elsewhere"
      @obj.disposition
    end

    def individual_count
      if @obj.class == Specimen
        1
      else
        @obj.total_specimens 
      end
    end

    # Darwin Core 1.4 Geospatial Element

    def decimal_latitude
      @ce.andand.latitude.to_s
    end

    def decimal_longitude
      @ce.andand.longitude.to_s
    end

    def geodetic_datum
      # The ellipsoid, geodetic datum, or spatial reference system (SRS) upon which the geographic coordinates given in decimalLatitude and decimalLongitude as based.
      # Recommended best practice is use the EPSG code as a controlled vocabulary to provide an SRS, if known. 
      # Otherwise use a controlled vocabulary for the name or code of the geodetic datum, if known. 
      # Otherwise use a controlled vocabulary for the name or code of the ellipsoid, if known. If none of these is known, use the value "unknown".
      # Examples: "EPSG:4326", "WGS84", "NAD27", "Campo Inchauspe", "European 1950", "Clarke 1866". For discussion see http://code.google.com/p/darwincore/wiki/Location
    "unknown"
    end

    def coordinate_uncertainty_in_meters
      @ce.andand.dc_coordinate_uncertainty_in_meters.to_s
    end

    def point_radius_spatial_fit
      nil
    end

    def verbatim_coordinates 
      nil
    end

    def verbatim_latitude
      @ce.andand.dc_verbatim_latitude
    end

    def verbatim_longitude
      @ce.andand.dc_verbatim_longitude
    end

    def verbatim_coordinate_system
      # The spatial coordinate system for the verbatimLatitude and verbatimLongitude or the verbatimCoordinates of the Location. Recommended best practice is to use a controlled vocabulary.
      # Comment:	Examples: "decimal degrees", "degrees decimal minutes", "degrees minutes seconds", "UTM". For discussion see http://code.google.com/p/darwincore/wiki/Location 
      # In table not in application (seriously, why bother?) 
      nil
    end

    def georeference_protocol
      @ce.andand.georeference_protocol.andand.display_name
    end

    def georeference_sources
      @ce.andand.dc_georeference_sources
    end

    def georeference_verification_status
      @ce.andand.dc_georeference_verification_status
    end

    def georeference_remarks
      @ce.andand.dc_georeference_remarks
    end

    def footprint_WKT
      nil
    end

    def footprint_spatial_fit
      nil
    end

    #== Misc DC
    def year 
      # (Start)
      # http://rs.tdwg.org/dwc/terms/history/index.htm#year-2009-04-24
      @ce && Strings.unify_from_roman(@ce.sd_y)
    end

    def month 
      # (Start)
      @ce && Strings.unify_from_roman(@ce.sd_m)
    end

    def day 
      # (Start)
      @ce && Strings.unify_from_roman(@ce.sd_d)
    end
    
    #== Mx housekeeping

    def otu_id
      @otu.andand.id
    end

    def taxon_name_id
      @taxon_name.andand.id
    end
    
    def proj_id
      @obj.proj_id
    end

    def specimen_id
      if @obj.class == Specimen
        @obj.id
      else
        nil
      end
    end

    def lot_id 
      if @obj.class == Lot 
        @obj.id
      else
        nil
      end
    end

    def ce_id
      @ce.andand.id
    end

    def ce_geog_id
      @ce.andand.geog_id
    end 

    #== Helper methods

    # We use this for housekeeping.
    def get_otu
      if @obj.class == Lot
        return @obj.otu
      elsif @obj.class == Specimen
        if o =  @obj.most_recent_determination
          if o.otu 
            return o.otu
          end
        end
      end
      return nil
    end

    def get_ce 
      if @obj.class == Lot
        @obj.ce
      elsif @obj.class == Specimen
        @obj.ce
      else
        return nil 
      end
    end

    def get_identifier
      ids = @obj.identifiers.that_are_catalog_numbers.ordered_by_position
      if ids.size > 0
        ids.first
      else
        nil
      end
    end

  end # End class Ipt

  # This module facilitates per project and multiple object serialization.
  module Batch
    protected

    def self.serialize_projects(options = {})
      opt = {
        :proj_ids => [] 
      }.merge!(options)

      result = nil

      opt[:proj_ids].each do |pid|
        result = update_project(pid) 
      end
      result
    end

    # Builds IptRecords for the Array of objects passed.
    def self.serialize_array(objects)
      invalid_objects = []
      valid_count = 0

      objects.each do |o|
        if i = IptOccurance.new(o)
          if i.serialize
            valid_count += 1
          else
            # This might become a memory issue with big datasets
            invalid_objects.push(o) 
          end
        else
          invalid_objects.push(o) 
        end
      end
      {:valid_count => valid_count, :invalid_objects => invalid_objects}
    end

    # Builds IptRecords for all objects in a project (lots and specimens).
    def self.update_project(proj_id)
      delete_from_project(proj_id)
      create_from_project(proj_id) 
    end

    protected 

    def self.create_from_project(proj_id)
      proj = Proj.find(proj_id)

      invalid_objects = []
      valid_count = 0

      ActiveRecord::Base.transaction do 
        (Specimen.find(:all, :conditions => {:proj_id => proj.id},
                       :include => 
                          [:repository, :identifiers,
                            {:ce => {:geog => [:geog_type, :country, :state, :county, :continent_ocean, :biogeo_region]}}, {:specimen_determinations => {:otu => {:taxon_name => [{:ref => :authors}, :parent]}}}]) + Lot.find(:all, :conditions => {:proj_id => proj.id}, :include => [:repository, :identifiers, {:otu => {:taxon_name => [:parent, {:ref => :authors}]}}, {:ce => {:geog => [:geog_type, :country, :state, :county, :continent_ocean, :biogeo_region]}}])
        ).each do |o|
          if i = IptOccurance.new(o).ipt_record
            if i.save
              valid_count += 1
            else
              # This might become a memory issue with big datasets
              invalid_objects.push(o) 
            end
          end
        end
      end
      {:valid_count => valid_count, :invalid_objects => invalid_objects}
    end

    def self.delete_from_project(proj_id)
      IptRecord.find_by_proj_id(proj_id).andand.delete
    end

  end


end
