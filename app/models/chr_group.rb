# == Schema Information
# Schema version: 20090930163041
#
# Table name: chr_groups
#
#  id              :integer(4)      not null, primary key
#  name            :string(255)
#  notes           :text
#  position        :integer(4)
#  content_type_id :integer(4)
#  proj_id         :integer(4)      not null
#  creator_id      :integer(4)      not null
#  updator_id      :integer(4)      not null
#  updated_on      :timestamp       not null
#  created_on      :timestamp       not null
#

class ChrGroup < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  has_many :chr_groups_chrs, :order => 'position', :dependent => :destroy
  has_many :chrs, :through => :chr_groups_chrs, :order => 'chr_groups_chrs.position'
  
  has_and_belongs_to_many :mxes
  belongs_to :content_type # this is how we map character data to content for matrix based descriptions 
 
  scope :with_content_type_mappings, :conditions => "content_type_id IS NOT NULL"

  acts_as_list :scope => :proj_id # we also use this order for content_type mapping

  before_destroy :update_matrices
  validates_presence_of :name

  # you MUST add characters with the add_chr(Chr) method, NOT << !!
  # similary remove them with remove_chr(Chr), not .delete

  def add_chr(o)
    # important! DO NOT add chrs like cg.chrs << chr, it WILL NOT WORK
    return false if !o.is_a?(Chr)
    if !self.chrs.include?(o)
      self.chr_groups_chrs.create(:chr_id => o.id)
      self.save

      self.mxes.each do |m|
        if !m.chrs_mxes.include?(Chr.find(o.id))  
          m.chrs_mxes.create(:chr_id => o.id, :mx_id => self.id) 
          m.save
        end
      end
      true
    else
      false
    end
  end

  def remove_chr(o)
    return false if !o.is_a?(Chr)
    # this is tricky, we want to fire the :before_destroy on a ChrGroupOtu so that we can sync
    # the matrices so DON'T USE .delete!!
    ChrGroupsChr.find_by_chr_id_and_chr_group_id(o.id, self.id).destroy
  end

  def display_name(options = {})
    opt = {:type => :select
      }.merge!(options.symbolize_keys)
      case opt[:type]
      when :for_select_list
        name
      else
        name
      end
  end

  def all_chr_txt
    s = ''
    self.chrs.each do |c|
      s << "#{c.name}: ["
      s <<  c.chr_states.map(&:name).join(" | ") 
      s << "];"
      s
    end
    s
  end

  def add_ungrouped_chrs
    Chr.without_groups.each do |c|
      self.add_chr(c)
    end
  end

  def self.auto_complete_search_result(params = {})
    @tag_id_str = params[:tag_id]
    value = params[@tag_id_str.to_sym]
    conditions = ["(chr_groups.name LIKE ? OR chr_groups.id = ?) and proj_id = ?",  "%#{value}%", value, params[:proj_id]]
    ChrGroup.find(:all, :conditions => conditions, :limit => 35, :order => 'chr_groups.name')
  end

  private
  # called on before_destroy
  def update_matrices
    self.mxes.each do |m|
      m.remove_group(self)
    end
  end

end
