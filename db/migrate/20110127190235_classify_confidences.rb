class ClassifyConfidences < ActiveRecord::Migration
  def self.up
      add_column :confidences, :applicable_model, :text, :size => 128, :null => true
  end

  def self.down
    remove_column :confidences, :applicable_model
  end
end
