class IptTable < ActiveRecord::Migration
  def self.up
    create_table (:ipt_records) do |t|
      
      # Darwin Core 1.4 (Draft Standard)
      t.string   :occurrence_id, :nil => false, :references => nil    # concat institution_code:colletion_code:catalog_number, <- IPT method
      t.datetime :modified                                       # http://dublincore.org/documents/dcmi-terms/#terms-modified 
      t.string   :basis_of_record, :nil => false                 # fixed for us, see Class::Ipt
      t.string   :institution_code, :nil => false                # repository.coden
      t.string   :collection_code, :nil => false                 # projects.collection_code <- must be present
      t.string   :catalog_number, :nil => false                  # is mx Namespace+Identifier from new Identifiers table with is_catalog_number true
      t.string   :information_withheld                           # !! not implemented
      t.text     :occurrence_remarks                             # 
      t.string   :scientific_name, :nil => false                 # determination at lowest level
      t.string   :parent_name_usage                              # HigherTaxon 	higherClassification
      t.string   :kingdom                                        # !! not implemented
      t.string   :phylum                                         # !!
      t.string   :tn_class                                       # !! class is reserved
      t.string   :tn_order                                       # !! order reserved
      t.string   :family                                         # 
      t.string   :genus                                          # 
      t.string   :specific_epithet                               #
      t.string   :taxon_rank, :size => 24                        # taxonomic rank
      t.string   :infraspecific_epithet                          # 
      t.string   :scientific_name_authorship                     # with parens
      t.string   :nomenclatural_code, :size => 16                #
      t.string   :identification_qualifier                       # !! like 'cf.' or 'nr.' <- implmented at OTU level, therfor not here
      t.string   :higher_geography                               # Ce#geography
      t.string   :continent                                      # full name
      t.string   :water_body                                     # full name
      t.string   :island_group                                   # 
      t.string   :island                                         #
      t.string   :country 
      t.string   :state_province  
      t.string   :county
      t.string   :locality 
      t.float    :minimum_elevation_in_meters      
      t.float    :maximum_elevation_in_meters
      t.float    :minimum_depth_in_meters                        # !! not implmented?
      t.float    :maximum_depth_in_meters
      t.string   :sampling_protocol                              # verbatim collecting method
      t.string   :establishment_means 
      t.datetime :event_date                          
      t.integer  :start_day_of_year, :size => 3                  # ordinal 1-365 if latest/earliest both exist don't populate
      t.string   :recorded_by                                    # concat by commas
      t.string   :sex                                            # full words
      t.string   :life_stage                                     # full words
      t.string   :dynamic_properties                             # !! additional elements, in the format "element: value;"
      t.string   :associated_media                               # a full URL reference to digital images
      t.string   :occurrence_details                             # !! urls, public content, etc.
          
      # Darwin Core 1.4 Curatorial extension
      t.float    :catalog_number                                 # only the number bit when identifier
      t.string   :identified_by                                  # who applied scientific name determination creator_id or name
      t.datetime :date_identified                                
      t.string   :record_number                                  # potentially an identifier (or all identifiers) that are not catalog numbers in new system
      t.string   :field_number                                   # ce tripcode (a single event)
      t.string   :field_notes                                    # !! we basically don't have this yes/no or URL or Notes <- micro/macro habitat?!
      t.string   :verbatim_event_date                       #
      t.string   :verbatim_elevation, :size => 24                #
      t.string   :verbatim_depth, :size => 24                    # !! don't have
      t.string   :preparations                                   
      t.string   :type_status                                    # a list of one or more nomeclatural types, e.g. "Holotype of Aus Bus (Ralph). Original description"
      t.string   :associated_sequences                           # a list of associated sequences?
      t.string   :other_catalog_numbers                          # fully qualified catalog numbers (probably other identifers)
      t.string   :associated_occurrences                          # one or more GUIDs like (sibling of) URN:catalog:FMNH:Bird:12345 <- concat identifier string
      t.string   :disposition                                    
      t.integer  :individual_count                               # specimens are 1, lots are sum
      
      # Darwin Core 1.4 Geospatial Element
      t.float    :decimal_latitude
      t.float    :decimal_longitude
      t.string   :geodetic_datum                          # see ce, not fieldified
      t.decimal  :coordinate_uncertainty_in_meters        # see ce, not fieldified 
      t.decimal  :point_radius_spatial_fit                # !! not implemented
      t.string   :verbatim_coordinates                    # !! not implemented
      t.string   :verbatim_latitude, :size => 128                       
      t.string   :verbatim_longitude, :size => 128        
      t.string   :verbatim_coordinate_system              # see ce, not fieldified
      t.string   :georeference_protocol                   # see ce, not fieldified
      t.string   :georeference_sources                    # not implemented (list of resources used, comma delimited)
      t.string   :georeference_verification_status 	 	    # implemented?
      t.string   :georeference_remarks                    # explains assumptions
      t.string   :footprint_WKT                           
      t.decimal  :footprint_spatial_fit                   # 0-1

      # Mx housekeeping
      t.integer  :proj_id, :size => 11, :references => :projs
      t.integer  :specimen_id, :size => 11, :references => :specimens
      t.integer  :lot_id, :size => 11, :references => :lots
      t.integer  :ce_id, :size => 11, :references => :ces
      t.integer  :ce_geog_id, :size => 11, :references => :geogs
      t.integer  :otu_id, :size => 11, :references => :otus
      t.integer  :taxon_name_id, :size => 11, :references => :taxon_names
      t.timestamps
    end

    add_index :ipt_records, :occurrence_id, :unique => true
    add_index :ipt_records, [:proj_id, :specimen_id]
    add_index :ipt_records, [:proj_id, :lot_id]
    add_index :ipt_records, [:proj_id, :ce_id]
    add_index :ipt_records, [:ce_id, :specimen_id]
    add_index :ipt_records, [:ce_id, :lot_id]
    add_index :ipt_records, [:occurrence_id, :institution_code, :collection_code, :catalog_number, :scientific_name], :unique => true, :name => 'ipt_uniqe'
  end

  def self.down
    drop_table :ipt_records
  end
end
