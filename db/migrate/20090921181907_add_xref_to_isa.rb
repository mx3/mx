class AddXrefToIsa < ActiveRecord::Migration
  def self.up
    add_column :isas, :xref, :string
  end

  def self.down
    remove_column :isas, :xref
  end
end
