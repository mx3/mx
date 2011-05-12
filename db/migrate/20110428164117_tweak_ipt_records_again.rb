class TweakIptRecordsAgain < ActiveRecord::Migration
  def self.up
    # Screw battling column definitions- just make it a string
    change_column :ipt_records, :minimum_elevation_in_meters, :string, :size => 128
    change_column :ipt_records, :maximum_elevation_in_meters, :string, :size => 128
    change_column :ipt_records, :maximum_depth_in_meters, :string, :size => 128
    change_column :ipt_records, :minimum_depth_in_meters, :string, :size => 128
    change_column :ipt_records, :decimal_longitude, :string, :size => 128
    change_column :ipt_records, :decimal_latitude, :string, :size => 128
    change_column :ipt_records, :coordinate_uncertainty_in_meters, :string, :size => 128
    change_column :ipt_records, :point_radius_spatial_fit, :string, :size => 128
    change_column :ipt_records, :footprint_spatial_fit, :string, :size => 128
    change_column :ipt_records, :associated_media, :text   
  end

  def self.down
  end
end
