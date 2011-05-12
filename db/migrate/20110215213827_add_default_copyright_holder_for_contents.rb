class AddDefaultCopyrightHolderForContents < ActiveRecord::Migration
  def self.up
    add_column :projs, :default_copyright_holder, :string
    add_column :contents, :copyright_holder, :string
  end

  def self.down
    remove_column :projs, :default_copyright_holder
    remove_column :contents, :copyright_holder
  end
end
