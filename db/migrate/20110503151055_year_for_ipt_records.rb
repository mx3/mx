class YearForIptRecords < ActiveRecord::Migration
  def self.up
    add_column :ipt_records, :year, :string, :size => 4
    add_column :ipt_records, :month, :string, :size => 2
    add_column :ipt_records, :day, :string, :size => 2
  end

  def self.down
  end
end
