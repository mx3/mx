# == Schema Information
# Schema version: 20090930163041
#
# Table name: figures
#
#  id                      :integer(4)      not null, primary key
#  addressable_id          :integer(4)
#  addressable_type        :string(64)
#  image_id                :integer(4)      not null
#  position                :integer(1)
#  caption                 :text
#  updated_on              :timestamp       not null
#  created_on              :timestamp       not null
#  creator_id              :integer(4)      not null
#  updator_id              :integer(4)      not null
#  proj_id                 :integer(4)      not null
#  morphbank_annotation_id :integer(4)
#  svg_txt                 :text
#


# TODO: Where is this used?!
class StateFigure < Figure
  belongs_to :chr_state, :foreign_key => "other_id"
end
