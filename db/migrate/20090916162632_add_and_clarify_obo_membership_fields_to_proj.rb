class AddAndClarifyOboMembershipFieldsToProj < ActiveRecord::Migration
  # you need to reset your the exclusion/restrictor keyword_id in the project here if you have it set (likely noone will)
  def self.up
    add_column :projs, :ontology_inclusion_keyword_id, :integer, :references => :keywords, :foreign_key => 'id'
    remove_column :projs, :restrictor_keyword_id
    add_column :projs, :ontology_exclusion_keyword_id, :integer, :references => :keywords, :foreign_key => 'id'
  end

  def self.down
    remove_column :projs, :ontology_inclusion_keyword_id
    add_column :projs, :restrictor_keyword_id, :integer, :references => :keywords, :foreign_key => 'id'
  end
end
