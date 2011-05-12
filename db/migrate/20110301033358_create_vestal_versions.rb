class CreateVestalVersions < ActiveRecord::Migration
  # hacked to work with FK migration plugins (ugh)
  def self.up
    create_table :versions do |t|
      t.integer :versioned_id, :length => 11, :references => nil
      t.string :versioned_type, :length => 255
      t.integer :user_id, :length => 11, :references => nil
      t.string :user_type, :length => 255
      t.string :user_name
      t.text :changes
      t.integer :number
      t.string :tag

      t.timestamps
    end

    change_table :versions do |t|
      t.index [:versioned_id, :versioned_type]
      t.index [:user_id, :user_type]
      t.index :user_name
      t.index :number
      t.index :tag
      t.index :created_at
    end
  end

  def self.down
    drop_table :versions
  end
end
