class AddDispositionToLot < ActiveRecord::Migration
  def self.up
    add_column :lots, :disposition, :string, :size => 256
  end

  def self.down
    remove_column :lots, :disposition
  end
end
