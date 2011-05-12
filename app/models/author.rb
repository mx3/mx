# == Schema Information
# Schema version: 20090930163041
#
# Table name: authors
#
#  id             :integer(4)      not null, primary key
#  ref_id         :integer(4)      not null
#  position       :integer(4)
#  last_name      :string(255)     not null
#  first_name     :string(255)
#  title          :string(255)
#  initials       :string(8)
#  auth_is        :string(16)      default("author"), not null
#  use_initials   :boolean(1)
#  name_with_init :string(255)
#  join_name      :string(255)
#  namespace_id   :integer(4)
#  external_id    :integer(4)
#  creator_id     :integer(4)      not null
#  updator_id     :integer(4)      not null
#  updated_on     :timestamp       not null
#  created_on     :timestamp       not null
#

class Author < ActiveRecord::Base
  has_standard_fields
  belongs_to :ref
  validates_presence_of :last_name 
  validates_format_of :initials, :with => /^[\w\s]*$/, :message => "cannot contain punctuation"

  acts_as_list :scope => :ref

  ## need to strip spaces/periods where unanticipated
  def display_name(options = {})
    last_name + (first_name_initials.blank? ? '' : ( ", " + first_name_initials))
  end

  # TODO: deprecate for above
  def display_name_initials_first 
   first_name_initials.blank? ? last_name : "#{first_name_initials} #{last_name}" 
  end

  # TODO: deprecate for above
  def first_name_initials # allows for > 1 first name
      i = ''
      if first_name? && first_name.include?('-')  # handle the first name if dashed
        i = first_name.split('-').map{|o| o.split('').first << '.'}.join('-')
      elsif first_name?
        i = first_name.split.map{|o| o.split('').first << '.'}.join(' ')
      end  
      i << ' ' + initials.gsub(/[\.\,]*/, '').split('').collect{|o| "#{o}."}.join(' ') if not initials.blank?
      i.strip
  end
 
end
