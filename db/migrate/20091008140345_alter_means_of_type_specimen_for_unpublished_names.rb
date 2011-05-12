class AlterMeansOfTypeSpecimenForUnpublishedNames < ActiveRecord::Migration
  def self.up
    change_column :type_specimens, :specimen_id, :integer, :null => true
    change_column :type_specimens, :type_type, :string, :limit => 24, :null => false
  end

  def self.down
    change_column :type_specimens, :specimen_id, :integer, :null => false
    change_column :type_specimens, :type_type, :string, :null => true, :limit => 24
  end
end
