class TweakNamespaces < ActiveRecord::Migration
  def self.up
	 change_column :namespaces, :last_loaded_on, :datetime, :null => true, :default => nil 
  end

  def self.down
   raise ActiveRecord::IrreversibleMigration
  end
end
