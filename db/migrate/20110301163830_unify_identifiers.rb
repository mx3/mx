class UnifyIdentifiers < ActiveRecord::Migration
  def self.up

    create_table(:identifiers) do |t|
      t.integer   :addressable_id, :references => nil
      t.string    :addressable_type
      t.integer   :namespace_id, :size => 11
      t.string    :identifier
      t.string    :global_identifier
      t.string    :global_identifier_type
      t.integer   :position
      t.string    :cached_display_name
      t.boolean   :is_catalog_number, :default => true
      t.text      :notes 
      t.integer   :proj_id, :size => 11
      t.integer   :creator_id, :references => :people, :size => 11
      t.integer   :updator_id, :references => :people, :size => 11
      t.datetime  :created_on
      t.datetime  :updated_on
    end

    add_index :identifiers, :addressable_id
    add_index :identifiers, :addressable_type
    add_index :identifiers, :identifier
    add_index :identifiers, :global_identifier
    add_index :identifiers, :namespace_id
    add_index :identifiers, :cached_display_name
    add_index :identifiers, [:namespace_id, :identifier]
    add_index :identifiers, [:global_identifier_type, :global_identifier], :name => 'gidt_gid'
    add_index :identifiers, [:addressable_type, :addressable_id]


  # UNCOMMENT IF YOU HAVEN'T MIGRATED FULLY

  ## write over, erase in a different migration 
  # print "transfering specimen identifiers ..."
  # SpecimenIdentifier.find(:all).each do |sid|
  #  # puts sid.to_yaml
  #   $proj_id = sid.specimen.proj_id
  #   t = Identifier.find_by_namespace_id_and_identifier(sid.namespace_id, sid.identifier) 
  #   
  #   id = Identifier.new(:addressable_type => 'Specimen',
  #                      :addressable_id => sid.specimen_id,
  #                      :identifier => (t.blank? ? sid.identifier : "#{sid.identifier} (#{sid.created_on})"), 
  #                      :namespace_id => sid.namespace_id,
  #                      :creator_id => sid.creator_id,
  #                      :updator_id => sid.updator_id,
  #                      :created_on => sid.created_on,
  #                      :updated_on => sid.updated_on)
  #   id.save!
  # end
  # print "done\n"

  # 
  # print "transferring lot identifiers ..."

  # LotIdentifier.find(:all).each do |sid|
  #   $proj_id = sid.lot.proj_id
  #   t = Identifier.find_by_namespace_id_and_identifier(sid.namespace_id, sid.identifier) 

  #   id = Identifier.new(:addressable_type => 'Lot',
  #                      :addressable_id => sid.lot_id,
  #                      :identifier => (t.blank? ? sid.identifier : "#{sid.identifier} (#{sid.created_on})"), 
  #                      :namespace_id => sid.namespace_id,
  #                      :creator_id => sid.creator_id,
  #                      :updator_id => sid.updator_id,
  #                      :created_on => sid.created_on,
  #                      :updated_on => sid.updated_on)
  #   id.save!
  # end
 
  # print "done\n"


  end

  def self.down
    drop_table(:identifiers)
  end
end
