class AddLicenseToContents < ActiveRecord::Migration
  def self.up
    add_column :contents, :license, :string 
  end

  def self.down
    remove_column :contents, :license
  end
end
