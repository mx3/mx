# == Schema Information
# Schema version: 20090930163041
#
# Table name: serials
#
#  id                 :integer(4)      not null, primary key
#  name               :string(1024)
#  city               :string(255)
#  atTAMU             :string(12)
#  notes              :text
#  URL                :text
#  call_num           :string(255)
#  abbreviation       :string(255)
#  synonymous_with_id :integer(4)
#  language_id        :integer(4)
#  namespace_id       :integer(4)
#  external_id        :integer(4)
#  issn_print         :string(10)
#  creator_id         :integer(4)      not null
#  updator_id         :integer(4)      not null
#  updated_on         :timestamp       not null
#  created_on         :timestamp       not null
#  issn_digital       :string(255)
#

class Serial < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::Taggable
  
  belongs_to :synonymous_with, :class_name => "Serial", :foreign_key => 'synonymous_with_id'
  belongs_to :language
  
  has_many :refs, :order => 'refs.cached_display_name'

  validates_presence_of :name

  def display_name(options = {})
    opt = {
     :type => nil
    }.merge!(options.symbolize_keys)
    s = ''
    case opt[:type]
    when :selected
      name
    when :for_select_list
      "#{name}  <span class=\"small_grey\">(id: #{serial.id})</span>"
    else
      name
    end
  end

  def biostor_table
    str = %w(title authors year volume issue pg_start pg_end).join("\t") + "\n"
    str << self.refs.collect{|r| [r.title, r.authors_for_display, r.year, r.volume, r.issue, r.pg_start, r.pg_end].join("\t")}.join("\n")
    str
  end

  # some sampling utility 
  def random_refs(size)
    (1..size).collect{ self.refs[rand(self.refs.size)] } 
  end

  def groups_of_random_refs(group_size, ref_size)
    full_list = []
    result_list

    (1..group_size).each do 
      tmp_result = []
      (1.ref_size).each do   
      ref = self.refs[rand(self.refs.size)]
      while !full_list.include?(ref)
        ref = self.refs[rand(self.refs.size)]
      end
      tmp_result.push ref
      full_list.push ref 
    end
     
    
    end

  end

end
