class AddOtuUniquenessSettingsToProjs < ActiveRecord::Migration
  def self.up
    add_column :projs, :otu_uniqueness, :text
  end

  def self.down
    remove_column :projs, :otu_uniqueness
  end
end
