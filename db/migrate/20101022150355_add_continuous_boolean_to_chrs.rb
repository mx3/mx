class AddContinuousBooleanToChrs < ActiveRecord::Migration
  def self.up
    add_column :chrs, :is_continuous, :boolean, :default => false
  end

  def self.down
    remove_column :chrs, :is_continuous
  end
end
