class TweakDistributionTable < ActiveRecord::Migration
  def self.up
    remove_column :distributions, :num_specimens
    change_column :distributions, :introduced, :integer, :size => 3
    execute %{update distributions set introduced = 2 where introduced is null;}
  end

  def self.down
  end
end
