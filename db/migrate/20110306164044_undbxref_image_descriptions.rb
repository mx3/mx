class UndbxrefImageDescriptions < ActiveRecord::Migration
  def self.up
    rename_column :image_descriptions, :ontology_class_dbxref, :ontology_class_xref
  end

  def self.down
    rename_column :image_descriptions, :ontology_class_xref, :ontology_class_dbxref
  end
end
