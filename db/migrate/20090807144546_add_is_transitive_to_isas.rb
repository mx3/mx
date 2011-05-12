class AddIsTransitiveToIsas < ActiveRecord::Migration
  def self.up
    add_column :isas, :is_transitive, :boolean 
    add_column :isas, :is_reflexive, :boolean 
    add_column :isas, :is_anti_symmetric, :boolean 
  end

  def self.down
    remove_column :isas, :is_transitive
    remove_column :isas, :is_reflexive
    remove_column :isas, :is_anti_symmetric
  end
end
