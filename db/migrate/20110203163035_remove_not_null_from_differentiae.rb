class RemoveNotNullFromDifferentiae < ActiveRecord::Migration
  def self.up
    change_column :differentiae, :ontology_composition_id, :integer, :null => true
  end

  def self.down
    change_column :differentiae, :ontology_composition_id, :integer, :null => false
  end
end
