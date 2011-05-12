class CreateLabelsRefs < ActiveRecord::Migration
  def self.up
    execute %{create table labels_refs ENGINE=INNODB select * from parts_refs;}
    execute %{alter  table labels_refs modify id integer not null auto_increment primary key;}

    rename_column :labels_refs, :part_id, :label_id

    change_table :labels_refs do |t|
      t.change :label_id, :integer, :size => 11, :null => false
      t.change :ref_id, :integer, :size => 11, :null => false
      t.change :total, :integer, :size => 11, :null => false, :default => 0
    end

    execute %{alter table labels_refs add foreign key (ref_id) references refs(id);}
    execute %{alter table labels_refs add foreign key (label_id) references labels(id);}
    add_index :labels_refs, [:ref_id, :label_id]
  end

  def self.down
    drop_table :parts_refs
  end

end
