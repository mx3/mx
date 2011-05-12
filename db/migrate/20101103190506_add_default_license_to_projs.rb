class AddDefaultLicenseToProjs < ActiveRecord::Migration
  def self.up
    add_column :projs, :default_license, :string
  end

  def self.down
    remove_column :projs, :default_license
  end
end
