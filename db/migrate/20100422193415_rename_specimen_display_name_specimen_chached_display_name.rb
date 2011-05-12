class RenameSpecimenDisplayNameSpecimenChachedDisplayName < ActiveRecord::Migration
  def self.up
    rename_column :specimen_identifiers, :display_name, :cached_display_name
  end

  def self.down
    rename_column :specimen_identifiers, :cached_display_name, :display_name
  end
end
