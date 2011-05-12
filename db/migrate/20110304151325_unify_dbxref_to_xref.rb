class UnifyDbxrefToXref < ActiveRecord::Migration
  def self.up
    rename_column :ontology_classes, :dbxref, :xref
    rename_column :keywords, :is_dbxref, :is_xref
    rename_column :refs, :dbxref, :xref
  end

  def self.down
    rename_column :ontology_classes, :xref, :dbxref
    rename_column :keywords, :is_xref, :is_dbxref
    rename_column :refs, :xref, :dbxref
  end
end
