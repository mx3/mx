class UpdateContentTypeStiTypes < ActiveRecord::Migration
  def self.up
    execute %{update content_types set sti_type = concat("ContentType::", sti_type);}
  end

  def self.down
    # meh
  end
end
