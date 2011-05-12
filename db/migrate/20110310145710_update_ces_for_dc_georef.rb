class UpdateCesForDcGeoref < ActiveRecord::Migration
  def self.up
    add_column :ces, :dc_georeference_sources, :text
  end

  def self.down
    remove_column :ces, :dc_georeference_sources
  end
end
