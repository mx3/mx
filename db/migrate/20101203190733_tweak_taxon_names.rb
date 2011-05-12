class TweakTaxonNames < ActiveRecord::Migration
  def self.up
    change_column :taxon_names, :page_validated_on, :string
    change_column :taxon_names, :page_first_appearance, :string
    add_column    :taxon_names, :agreement_name, :string
    add_column    :taxon_name_status, :status_type, :string
  end

  def self.down
    change_column :taxon_names, :page_validated_on, :string
    change_column :taxon_names, :page_first_appearance, :string
    remove_column :taxon_names, :agreement_name
    remove_column :taxon_name_status, :status_type
  end
end
