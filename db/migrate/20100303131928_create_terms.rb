class CreateTerms < ActiveRecord::Migration
  # this is a project level utility table primarily for use in proofing functions
  def self.up
    execute %{create table terms ENGINE=INNODB select id, name, count "proofer_ignored", proj_id, created_on, updated_on from term_exclusions;}
    execute %{alter table terms modify id integer not null auto_increment primary key;}

    add_column :terms, :common, :boolean, :default => false
    add_column :terms, :common_votes, :integer, :default => 0     # number of human votes for "common"
    add_column :terms, :proofer_count, :integer, :default => 0
    add_column :terms, :common_threshold, :decimal, :default => 0 # some calculation (stub)
    add_column :terms, :ontologize_IP_votes, :text

  end

  def self.down
    drop_table :terms
  end
end
