class RevertApiAttemptForProjs < ActiveRecord::Migration
  def self.up
    remove_column :projs, :api_name
  end

  def self.down
    add_column :projs, :api_name, :string
  end
end
