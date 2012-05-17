class DeprecateOtuIsChild < ActiveRecord::Migration
  def self.up
    remove_column :otus, :is_child
  end

  def self.down
    add_column :otus, :is_child, :boolean  
  end
end
