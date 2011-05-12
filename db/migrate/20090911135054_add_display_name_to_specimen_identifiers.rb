class AddDisplayNameToSpecimenIdentifiers < ActiveRecord::Migration
  def self.up
    add_column :specimen_identifiers, :display_name, :string
  end

  def self.down
    remove_column :specimen_identifiers, :display_name
  end
end
