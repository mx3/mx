class AddIsOcredToPdfs < ActiveRecord::Migration
  def self.up
    add_column :pdfs, :is_ocred, :boolean
  end

  def self.down
    remove_column :pdfs, :is_ocred
  end
end
