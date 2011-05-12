class AddRefsEmailPreferenceToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :pref_receive_reference_update_emails, :boolean, :default => false
  end

  def self.down
    remove_column :people, :pref_receive_reference_update_emails
  end
end
