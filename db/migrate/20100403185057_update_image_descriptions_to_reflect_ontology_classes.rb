class UpdateImageDescriptionsToReflectOntologyClasses < ActiveRecord::Migration
  def self.up
      execute %{ALTER TABLE image_descriptions DROP FOREIGN KEY image_descriptions_ibfk_5;} # the one on parts
      rename_column :image_descriptions, :part_id, :label_id
      add_index :image_descriptions, [:label_id]
      execute %{alter table image_descriptions add foreign key (label_id) references labels(id);}
  end

  def self.down
    # don't bother
  end
end
