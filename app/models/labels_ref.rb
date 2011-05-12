class LabelsRef < ActiveRecord::Base

  # this is strictly a utility class so that we can cached counts of terms found in references

  has_standard_fields
  belongs_to :ref
  belongs_to :label
  
  validates_uniqueness_of 'label_id', :scope => 'ref_id'

end
