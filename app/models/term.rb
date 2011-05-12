class Term < ActiveRecord::Base
  serialize :ontologize_IP_votes
 
  belongs_to :proj

  validates_presence_of :name

end
