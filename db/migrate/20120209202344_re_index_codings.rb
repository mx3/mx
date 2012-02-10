class ReIndexCodings < ActiveRecord::Migration
  def self.up
    add_index(:codings, [:chr_id, :otu_id], :name => 'matrixspeed')
  end

  def self.down
    remove_index :codings, :name => 'matrixspeed'
  end
end
