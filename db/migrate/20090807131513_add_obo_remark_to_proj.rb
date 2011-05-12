class AddOboRemarkToProj < ActiveRecord::Migration
  def self.up
    add_column :projs, :obo_remark, :text
  end

  def self.down
    remove_column :projs, :obo_remark
  end
end
