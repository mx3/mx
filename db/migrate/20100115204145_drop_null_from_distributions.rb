class DropNullFromDistributions < ActiveRecord::Migration
  def self.up
    change_column :distributions, :num_specimens, :integer, :null => true
  end

  def self.down
    change_column :distributions, :gene_id, :integer, :null => false
  end
end
