class AddOtuIdToTypeSpecimensForUndescribedSpecies < ActiveRecord::Migration
  def self.up
    add_column :type_specimens, :otu_id, :integer, :references => :otus, :size => 11
    change_column :type_specimens, :taxon_name_id, :integer, :size => 11, :references => :taxon_names, :null => true
    change_column :type_specimens, :specimen_id, :integer, :size => 11, :null => false, :references => :specimens
  end

  def self.down
    remove_column :type_specimens, :otu_id
  end
end
