class RemoveGenusDifferentia < ActiveRecord::Migration
  # turns out we're not using this
  def self.up
    remove_column :parts, :is_genus_differentia
  end

  def self.down
    add_column :parts, :is_genus_differentia, :boolean
  end
end
