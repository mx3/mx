class MakeOcrTextMediumText < ActiveRecord::Migration
  def self.up
    change_column :refs, :ocr_text, :mediumtext
  end

  def self.down
    change_column :refs, :ocr_text, :text
  end
end
