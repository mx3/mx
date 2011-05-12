class AddOcrTextFieldToMx < ActiveRecord::Migration
  def self.up
    add_column :refs, :ocr_text, :text
  end

  def self.down
   remove_column :refs, :ocr_text, :text
  end
end
