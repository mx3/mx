class ModifiyVsDarwinCore < ActiveRecord::Migration
  def self.up
     
    add_column :ces, :print_label, :text
    rename_column :ces, :label, :verbatim_label

    add_column :ces, :depth_min, :float
    add_column :ces, :depth_max, :float

    add_column :specimens, :preparations, :text 
 
    remove_column :specimens, :lost 
    add_column :specimens, :disposition, :string 
  end

  def self.down
    remove_column :ces, :print_label
    rename_column :ces, :verbatim_label, :label

    remove_column :ces, :depth_min
    rename_column :ces, :depth_max
    
    remove_column :specimens, :preparations

    add_column :specimens, :lost, :boolean
    remove_column :specimens, :disposition

  end
end
