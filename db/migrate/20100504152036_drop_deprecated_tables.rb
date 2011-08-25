class DropDeprecatedTables < ActiveRecord::Migration
  def self.up
    execute %{set foreign_key_checks = 0;}
    drop_table :hhs
    drop_table :hhs_statements
    execute %{set foreign_key_checks = 1;}
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
    
  end
end
