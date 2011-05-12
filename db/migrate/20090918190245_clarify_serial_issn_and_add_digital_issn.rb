class ClarifySerialIssnAndAddDigitalIssn < ActiveRecord::Migration
  def self.up
    rename_column :serials, :ISSN, :issn_print
    add_column :serials, :issn_digital, :string
  end

  def self.down
    remove_column :serials, :issn_digital
    rename_column :serials, :issn_print, :ISSN
  end
end
