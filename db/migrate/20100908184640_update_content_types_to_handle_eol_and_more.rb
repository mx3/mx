class UpdateContentTypesToHandleEolAndMore < ActiveRecord::Migration
  def self.up
      add_column :content_types, :doc_name, :string
      add_column :content_types, :subject, :string
      add_column :content_types, :render_as_subheading, :boolean, :default => false
  end

  def self.down
    remove_column :content_types, :doc_name, :string
    remove_column :content_types, :subject, :string
    remove_column :content_types, :render_as_subheading, :boolean, :default => false
  end
end
