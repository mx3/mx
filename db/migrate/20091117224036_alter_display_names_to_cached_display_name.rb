class AlterDisplayNamesToCachedDisplayName < ActiveRecord::Migration
  def self.up
    rename_column :refs, :display_name, :cached_display_name
    rename_column :taxon_names, :display_name, :cached_display_name
  end

  def self.down
    rename_column :taxon_names, :cached_display_name, :display_name
    rename_column :refs, :cached_display_name, :display_name
  end
end
