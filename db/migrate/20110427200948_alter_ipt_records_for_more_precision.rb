class AlterIptRecordsForMorePrecision < ActiveRecord::Migration
  def self.up
    change_column :ipt_records, :minimum_elevation_in_meters, :decimal
    change_column :ipt_records, :maximum_elevation_in_meters, :decimal
    change_column :ipt_records, :maximum_depth_in_meters, :decimal
    change_column :ipt_records, :minimum_depth_in_meters, :decimal
    change_column :ipt_records, :decimal_longitude, :decimal
    change_column :ipt_records, :decimal_latitude, :decimal
    change_column :ipt_records, :event_date, :string
  end

  def self.down
  end
end
