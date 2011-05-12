class AddStageToLot < ActiveRecord::Migration
  def self.up
    add_column :lots, :stage, :string
  end

  def self.down
    remove_column :lots, :stage
  end
end
