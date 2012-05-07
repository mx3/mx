class AddRefIdToCes < ActiveRecord::Migration
  def self.up
    add_column :ces, :ref_id, :integer, :size => 11
    execute %{alter table ces add FOREIGN KEY `ref_id` (ref_id) REFERENCES refs(id);}
  end

  def self.down
    remove_column :ces, :ref_id
  end
end
