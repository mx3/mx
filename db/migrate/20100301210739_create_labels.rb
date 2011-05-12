class CreateLabels < ActiveRecord::Migration
  def self.up
    execute %{create table labels ENGINE=INNODB select id, name, language_id, proj_id, creator_id, updator_id, created_on, updated_on from parts ;}
    execute %{alter table labels modify id integer not null auto_increment primary key;}

    Label.reset_column_information 
    change_table :labels do |t|
      t.change :name, :string, {:limit => 255, :null => false}
      t.change :language_id, :integer,:limit => 11
      t.change :updator_id, :integer, :limit => 11, :null => false
      t.change :creator_id, :integer, :limit => 11, :null => false
      t.change :proj_id, :integer, :references => :projs, :limit => 11, :null => false
    end

    execute %{alter table labels add  foreign key (proj_id) references projs(id);}
    execute %{alter table labels add  foreign key (updator_id) references people(id);}
    execute %{alter table labels add  foreign key (creator_id) references people(id);}
    execute %{alter table labels add  foreign key (language_id) references languages(id);}

    add_column :labels, :classify_IP_votes, :text      # serialized array of IP addresses 1/vote
    add_column :labels, :plural_of_label_id, :integer, :references => :labels, :limit => 11, :null => true

    add_column :labels, :active_on, :timestamp         # track when this was used in other models

    add_index :labels, :name
    add_index :labels, [:proj_id, :name, :language_id], :unique => true
  end

  def self.down
    drop_table :labels
  end
end
