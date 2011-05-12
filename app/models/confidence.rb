# == Schema Information
# Schema version: 20090930163041
#
# Table name: confidences
#
#  id         :integer(4)      not null, primary key
#  name       :string(128)
#  position   :integer(4)
#  short_name :string(4)
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#  html_color :string(8)
#

class Confidence < ActiveRecord::Base
 
  MODELS_WITH_CONFIDENCE = { # check vs. has_many below, used in selects
    'sequences' => 'seq',
    'pcrs' => 'pcr',
    'collecting events' => 'ce',
    'associations' => 'association_support',
    'matrix codings' => 'coding'
  } 

  has_standard_fields  
  acts_as_list :scope => :proj
  has_many :association_supports, :dependent => :nullify 
  has_many :codings, :dependent => :nullify
  has_many :pcrs, :dependent => :nullify
  has_many :ces, :foreign_key => 'locality_accuracy_confidence_id'

  belongs_to :proj
  validates_presence_of :name
  validates_presence_of :applicable_model 
  validates_uniqueness_of :name, :scope => 'proj_id'
  validates_length_of :html_color, :is => 6, :allow_blank => true

  # prefix a confidence like Foo: some confidence to make it applicable to objects of a given type
  scope :by_namespace, lambda {|*args| {:conditions => ["name like ?", (args.first ? "#{args.first.to_s.downcase}:%" : -1) ]}}  # TO BE DEPRECATED FOR BELOW

  scope :by_model, lambda {|*args| {:conditions => ["confidences.applicable_model = ?", (args.first ? args.first : -1) ]}} 

  def display_name(options = {})
     @opt = {
      :type => :list # :list, :head, :select, :sub_select
     }.merge!(options.symbolize_keys)
     case @opt[:type]
     when :selected
        name 
     when :for_select_list
        name
     when :short
       open_background_color_span + short_name + '</span>'
     else
        open_background_color_span + name + '</span>'
     end
  end

  # TODO: move to helper 
  def open_background_color_span
    "<span style=\"background-color:##{self.html_color};\">"
  end

  # cargoed from Ref#delete_or_replace_with
  def merge_with(confidence = nil)
    return if confidence == self 
    return nil if confidence.class != Confidence
    assocs = self.class.reflect_on_all_associations
    begin 
      Confidence.transaction do  
        assocs.select{|a| a.macro == :has_many}.each do |assoc|
          klass = Kernel.const_get(assoc.class_name)
          klass.find(:all, :conditions => {:proj_id => self.proj_id, :confidence_id => self.id}).each do |k|
            k.update_attributes!(:confidence_id => confidence.id)
          end
        end
     end 
    rescue
    end
  end
end
