class AddVerbatimCeMd5 < ActiveRecord::Migration
  
  def self.up
    add_column :ces, :verbatim_label_md5, :string, :length => 32
  end

  def self.down
    remove_column :ces, :verbatim_label_md5
  end
  
end
