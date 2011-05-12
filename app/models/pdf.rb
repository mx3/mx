# == Schema Information
# Schema version: 20090930163041
#
# Table name: pdfs
#
#  id           :integer(4)      not null, primary key
#  parent_id    :integer(4)
#  content_type :string(255)
#  filename     :string(1024)
#  size         :integer(4)
#  is_ocred     :boolean(1)
#

class Pdf < ActiveRecord::Base

  has_many :refs, :dependent => :nullify

  has_attachment  :content_type => 'application/pdf', # could add eps etc. too?
                  :storage => :file_system, 
                  :max_size => 100.megabytes,
                  :path_prefix => "public/files/pdfs"
  
  validates_as_attachment

end

