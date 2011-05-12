class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.timestamps
    end

    # do this outside so the Redhill auto foreign key backs off
    execute %{alter table sessions add data longtext;}
    execute %{alter table sessions add column session_id int(11);}

    add_index :sessions, :session_id
    add_index :sessions, :updated_at
  end

  def self.down
    drop_table :sessions
  end
end
