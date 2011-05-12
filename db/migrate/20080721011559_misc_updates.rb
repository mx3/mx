class MiscUpdates < ActiveRecord::Migration
 
  def self.up
    add_column :projs, :ontology_namespace, :string, :limit => 32   # namespace/project for ontology OBO Dump
    rename_column :repositories, :codon, :coden                     # spelling
    add_column :parts, :obo_dbxref, :string               

    add_column :codings, :confidence_id, :integer         
    execute %{ ALTER TABLE codings ADD CONSTRAINT `codings_confidence_fk` FOREIGN KEY  (confidence_id) REFERENCES confidences(id); }

    # getting rake db:clone_structure to work properly prior to rake test
    execute %{ALTER TABLE people CHANGE COLUMN middle_name middle_name VARCHAR(100);} 
  end

  def self.down
    remove_column :projs, :ontology_namespace 
    rename_column :repositories, :coden, :codon
    remove_column :parts, :obo_dbxref

    execute %{ ALTER TABLE codings DROP FOREIGN KEY codings_confidence_fk; }
    remove_column :codings, :confidence_id

    execute %{ALTER TABLE people CHANGE COLUMN middle_name middle_name VARCHAR(100) NOT NULL DEFAULT '';}
  end
end
