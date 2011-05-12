class DeprecateOldOntologiesClass < ActiveRecord::Migration
  def self.up
    drop_table :ontologies
  end

  def self.down
    # irreversible
  end
end
