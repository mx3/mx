class AddMakerAndEditorToContents < ActiveRecord::Migration
  def self.up
    add_column :contents, :maker, :string
    add_column :contents, :editor, :string
  end

  def self.down
    remove_column :contents, :maker
    remove_column :contents, :editor
  end
end
