class AddApiSubdomainToProj < ActiveRecord::Migration
  def self.up
    add_column :projs, :api_name, :string, :null => true
  end

  def self.down
    remove_column :projs, :api_name
  end
end
