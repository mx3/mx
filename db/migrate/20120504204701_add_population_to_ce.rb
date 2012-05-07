class AddPopulationToCe < ActiveRecord::Migration
  def self.up
    add_column :ces, :population, :text
  end

  def self.down
    remove_column :ces, :population
  end
end
