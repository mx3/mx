class PostIdentifierUnificationCleanup < ActiveRecord::Migration
  def self.up
    drop_table :specimen_identifiers
    drop_table :lot_identifiers
  end

  def self.down
  end
end
