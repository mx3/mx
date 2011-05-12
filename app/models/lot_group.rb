# == Schema Information
# Schema version: 20090930163041
#
# Table name: lot_groups
#
#  id                        :integer(4)      not null, primary key
#  name                      :string(255)     not null
#  notes                     :text
#  is_loan                   :boolean(1)      not null
#  outgoing_loan             :boolean(1)      not null
#  incoming_transaction_code :string(255)
#  repository_id             :integer(4)
#  material_requested        :text
#  date_requested            :date
#  date_recieved             :date
#  total_specimens_recieved  :integer(4)
#  loan_start_date           :date
#  loan_end_date             :date
#  specimens_returned_date   :date
#  loan_closed               :boolean(1)      not null
#  contact_name              :string(255)
#  contact_email             :string(255)
#  policy_page_url           :string(255)
#  loan_notes                :text
#  proj_id                   :integer(4)      not null
#  creator_id                :integer(4)      not null
#  updator_id                :integer(4)      not null
#  updated_on                :timestamp       not null
#  created_on                :timestamp       not null
#

class LotGroup < ActiveRecord::Base
  has_standard_fields
 
  belongs_to :repository
  has_and_belongs_to_many :lots
  
  validates_uniqueness_of :name, :scope => 'proj_id'
  
  def display_name(options = {})
    name
  end
 
end
