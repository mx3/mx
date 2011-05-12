class AddTimesToCe < ActiveRecord::Migration
  def self.up
    add_column :ces, :time_start, :time
    add_column :ces, :time_end, :time
  end

  def self.down
    remove_column :ces, :time_start
    remove_column :ces, :time_end
  end
end
