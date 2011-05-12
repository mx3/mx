class DropDeprecatedTables < ActiveRecord::Migration
  def self.up
    drop_table :hhs
    drop_table :hhs_statements
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
    
  end
end
