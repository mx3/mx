class AddPositionPriorityToSpecimenIdentifiers < ActiveRecord::Migration
  def self.up
    add_column :specimen_identifiers, :position, :integer
  end

  def self.down
    remove_column :specimen_identifiers, :position
  end
end
