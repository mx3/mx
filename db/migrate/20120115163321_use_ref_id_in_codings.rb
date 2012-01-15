class UseRefIdInCodings < ActiveRecord::Migration
  def self.up
    execute %{alter table codings drop FOREIGN KEY `codings_ibfk_6`;}
    rename_column :codings, :cited_in, :ref_id
    execute %{alter table codings add foreign key (ref_id) references refs(id);} 
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
