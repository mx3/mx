class AddIsDepletedToExtract < ActiveRecord::Migration
  def self.up
    add_column :extracts, :is_depleted, :boolean, :default => false
  end

  def self.down
    remove_column :extracts, :is_depleted
  end
end
