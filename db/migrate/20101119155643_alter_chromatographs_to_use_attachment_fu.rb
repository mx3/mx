class AlterChromatographsToUseAttachmentFu < ActiveRecord::Migration
  def self.up
    rename_column :chromatograms, :chromatograph_file, :filename
    add_column :chromatograms, :size, :integer
    add_column :chromatograms, :content_type, :string
  end

  def self.down
      rename_column :chromatograms, :filename, :chromatograph_file
  end
end
