class AddDefIsGenusDifferentiaToParts < ActiveRecord::Migration
  def self.up
    add_column :parts, :is_genus_differentia, :boolean
  end

  def self.down
    remove_column :parts, :is_genus_differentia
  end
end
