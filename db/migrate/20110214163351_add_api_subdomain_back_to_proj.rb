class AddApiSubdomainBackToProj < ActiveRecord::Migration
  # sigh- we really do need it
  def self.up
    add_column :projs, :api_name, :string, :null => true
  end

  def self.down
    remove_column :projs, :api_name
  end
end
