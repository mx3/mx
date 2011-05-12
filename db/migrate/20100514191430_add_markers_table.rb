class AddMarkersTable < ActiveRecord::Migration
  def self.up
    create_table :figure_markers do |t|
      t.primary_key :id
      t.text :svg, :null => false
      t.decimal :x_origin, :default => 0, :precision => 6
      t.decimal :y_origin, :default => 0, :precision => 6
      t.decimal :rotation, :default => 0, :precision => 6
      t.decimal :scale, :default => 0, :precision => 6
      t.string :marker_type, :default => 'area', :null => false, :size => 8 # point, line, area, volume 
      t.integer :position  
      t.timestamp :created_on, :null => false
      t.timestamp :updated_on, :null => false
    end

    add_column :figure_markers, :figure_id, :integer, :null => false, :size => 11, :references => :figures
    add_column :figure_markers, :proj_id,  :integer, :null => false, :size => 11, :references => :projs
    add_column :figure_markers, :updator_id, :integer, :references => :people, :size => 11, :null => false, :references => :people
    add_column :figure_markers, :creator_id, :integer, :references => :people, :size => 11, :null => false, :references => :people
      
    add_index :figure_markers, :figure_id 
  
  end

  def self.down
    drop_table :figure_markers
  end
end
