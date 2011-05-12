class Beat < ActiveRecord::Base
  has_standard_fields
  belongs_to :addressable, :polymorphic => true
end
