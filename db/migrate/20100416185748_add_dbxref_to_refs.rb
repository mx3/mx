class AddDbxrefToRefs < ActiveRecord::Migration
  def self.up
    add_column :refs, :dbxref, :string
  end

  def self.down
    remove_column :refs, :dbxref
  end
end
