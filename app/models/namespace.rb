class Namespace < ActiveRecord::Base
  has_standard_fields
  
  has_many :refs
  has_many :taxon_names  
  has_many :identifiers

  validates_presence_of :name, :short_name

  validate :check_record
  def check_record
    errors.add(:short_name, 'Short name can not contain whitespace') if self.short_name =~ /\s/
  end

  after_save :update_identifier_cached_display_name

  def display_name(options = {}) # :yields: String
    opt = {
     :type => nil 
    }.merge!(options.symbolize_keys)
    (short_name.blank? ? 'Legacy unpopulated namespace short name, please notify your administrator' : short_name ) + ": " + name 
  end

  def self.auto_complete_search_result(params = {}) # :yields: Array of Namespaces
    tag_id_str = params[:tag_id]
    return false if (tag_id_str == nil  || params[:proj_id].blank?)

    value = params[tag_id_str.to_sym].split.join('%') 

    lim = case params[tag_id_str.to_sym].length
          when 1..2 then 5
          when 3..4 then 10
          else lim = false # no limits
          end 
    Namespace.find(:all, :conditions => ["(namespaces.name LIKE ? OR namespaces.short_name LIKE ? OR namespaces.id = ?)", "%#{value}%", "%#{value}%", value.gsub(/\%/, "") ], :limit => lim, :order => 'name' )
  end
 
  protected

  def update_identifier_cached_display_name # :yields: true
    if self.short_name_changed?
      Namespace.transaction do 
        self.identifiers.each do |si|
          si.save!
        end
      end
    end
    true
  end
    
end
