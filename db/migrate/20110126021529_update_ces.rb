class UpdateCes < ActiveRecord::Migration
  def self.up
    add_column :ces, :micro_habitat, :text
    add_column :ces, :macro_habitat, :text
    add_column :ces, :locality_accuracy_confidence_id, :integer, :size => 11, :references => :confidences, :null => true

    # DarwinCore Verbatim Coordinate Terms
    add_column :ces, :dc_verbatim_SRS, :text, :size => 256    
    add_column :ces, :dc_verbatim_coordinate_system, :text, :size => 64   
    rename_column :ces, :label_lat, :dc_verbatim_latitude
    rename_column :ces, :label_lon, :dc_verbatim_longitude

    # DC Georeference Terms
    add_column :ces, :dc_geodetic_dataum, :text, :size => 256                
    add_column :ces, :dc_georeference_protocol_id, :integer, :size => 11, :references => :protocols
    add_column :ces, :dc_georeference_verification_status, :text, :size => 256 
    add_column :ces, :dc_footprint_SRS, :text, :size => 256                         
    
    # Other DC Georeference bits
    add_column :ces, :dc_georeferenced_by, :text
    add_column :ces, :dc_georeference_remarks, :text
    rename_column :ces, :lat_lon_error_m, :dc_coordinate_uncertainty_in_meters
    
    # DC Geographic Terms
    add_column :geogs, :iso_3166_1_alpha_2_code, :text, :size => 2
    
  end

  def self.down
     remove_column :ces, :micro_habitat, :text
     remove_column :ces, :macro_habitat, :text
     remove_column :ces, :locality_accuracy_confidence_id

     # DC Verbatim Coordinate Terms
     remove_column :ces, :dc_verbatim_SRS
     remove_column :ces, :dc_verbatim_coordinate_system
     rename_column :ces, :dc_verbatim_latitude, :label_lat 
     rename_column :ces, :dc_verbatim_longitude, :label_long

     # DC Georeference Terms
     remove_column :ces, :dc_geodetic_dataum
     remove_column :ces, :dc_georeference_protocol_id
     remove_column :ces, :dc_georeference_verification_status
     remove_column :ces, :dc_footprint_SRS       

     # Other DC Georeference bits
     remove_column :ces, :dc_georeferenced_by
     remove_column :ces, :dc_georeference_remarks
     rename_column :ces, :dc_coordinate_uncertainty_in_meters, :lat_lon_error_m

     # DC Geographic Terms
     remove_column :geogs, :iso_3166_1_alpha_2_code
  end
  
end
