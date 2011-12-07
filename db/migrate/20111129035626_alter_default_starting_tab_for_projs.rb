class AlterDefaultStartingTabForProjs < ActiveRecord::Migration
  def self.up
    change_column :projs, :starting_tab, :string,  { :default => 'otus', :limit => 32 }
  end

  def self.down
    change_column :projs, :starting_tab, :string,  {:default => 'otu', :limit => 32}
  end
end
