class AddLicenseToImages < ActiveRecord::Migration
  def self.up
    add_column :images, :license, :string
  end

  def self.down
    remove_column :images, :license
  end
end
