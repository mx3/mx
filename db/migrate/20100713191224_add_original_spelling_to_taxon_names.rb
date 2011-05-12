class AddOriginalSpellingToTaxonNames < ActiveRecord::Migration
  def self.up
    add_column :taxon_names, :original_spelling, :string
  end

  def self.down
    remove_column :taxon_names, :original_spelling, :string
  end
end
