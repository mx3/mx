class AddRestrictorKeywordIdForProjs < ActiveRecord::Migration
   def self.up
    add_column :projs, :restrictor_keyword_id, :integer, :references => :keywords, :foreign_key => 'id'
    add_index :projs, :restrictor_keyword_id
  end

  def self.down
    remove_index :projs, :restrictor_keyword_id
    remove_column :projs, :restrictor_keyword_id
  end
end
