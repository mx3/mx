class Identifier < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::DefaultNamedScopes

  GLOBAL_IDENTIFIER_TYPES = ['lsid', 'uri', 'isbn', 'xref', 'doi']

  belongs_to :addressable, :polymorphic => true
  belongs_to :namespace

  scope :by_class, lambda {|*args| {:conditions => ["identifiers.addressable_type = ?", (args.first || -1)] }}
  scope :with_addressable_id, lambda {|*args| {:conditions => ["identifiers.addressable_id = ?", (args.first || -1)] }}
  scope :with_global_identifier, lambda {|*args| {:conditions => ["identifiers.global_identifier = ?", (args.first || -1)] }}
  scope :that_are_global, :conditions => 'global_identifier IS NOT NULL' 
  scope :that_are_namespaced, :conditions => 'namespace_id IS NOT NULL' 
  scope :identifier, lambda {|*args| {:conditions => ["identifiers.identifier = ?", (args.first || -1)] }}
  scope :that_are_catalog_numbers, :conditions => 'is_catalog_number = 1'
  scope :by_global_identifier_type, lambda {|*args| {:conditions => ["identifiers.global_identifier_type = ?", (args.first || -1)] }}

  validates_presence_of :addressable_id
  validates_presence_of :addressable_type
  validates_uniqueness_of :global_identifier, :scope => [:proj_id], :allow_blank => true
  validates_uniqueness_of :identifier, :scope => [:proj_id, :namespace_id], :allow_blank => true

  validate :check_record
  def check_record
    errors.add(:global_identifier_type, "not a valid identifier type") if !global_identifier.blank? && !GLOBAL_IDENTIFIER_TYPES.include?(global_identifier_type)

    # essentially subclasses here
    if identifier.blank? && global_identifier.blank? 
      errors.add(:identifier, "provide one of identifier or global identifier") 
    end

    if !identifier.blank? && !global_identifier.blank?
      errors.add(:identifier, "provide only one of identifier or global identifier") 
      errors.add(:global_identifier, "provide only one of identifier or global identifier") 
    end

    if !global_identifier.blank? && global_identifier_type.blank?
      errors.add(:identifier, "must provide a gobal_identifier_type") 
    end

    if !identifier.blank? && namespace_id.blank?
      errors.add(:identifier, "must provide a namespace for the identifier") 
    end

    case global_identifier_type
    when 'lsid'
     # specimens (e.g., urn:lsid:zoobank.org:specimen:21B5F918-E570-4991-8114-149DA17A1B6A)
     # authors (urn:lsid:zoobank.org:author:7FE1A5BC-A6C3-4055-98EC-9B54A3A5A786)
     # taxon names (urn:lsid:zoobank.org:act:0E15D71A-8320-48BE-8683-6C6A2FFE7EAE)
     # references (urn:lsid:zoobank.org:pub:265CC10F-1D77-4CEE-A869-B9A60E4D8308)
     # http://biocol.org/<LSID string here>
     # http://zoobank.org/<LSID string here>

      errors.add(:global_identifier, 'lsids must start with "urn:lsid"') if not (global_identifier =~ /\Aurn\:lsid/)
    when 'uri'
      # lifted from http://stackoverflow.com/questions/30847/regex-to-validate-uris
      # errors.add(:global_identifier, 'Problem with URI format.') if (global_identifier =~ /^([a-z0-9+.-]+):(?://(?:((?:[a-z0-9-._~!$&'()*+,;=:]|%[0-9A-F]{2})*)@)?((?:[a-z0-9-._~!$&'()*+,;=]|%[0-9A-F]{2})*)(?::(\d*))?(/(?:[a-z0-9-._~!$&'()*+,;=:@/]|%[0-9A-F]{2})*)?|(/?(?:[a-z0-9-._~!$&'()*+,;=:@]|%[0-9A-F]{2})+(?:[a-z0-9-._~!$&'()*+,;=:@/]|%[0-9A-F]{2})*)?)(?:\?((?:[a-z0-9-._~!$&'()*+,;=:/?@]|%[0-9A-F]{2})*))?(?:#((?:[a-z0-9-._~!$&'()*+,;=:/?@]|%[0-9A-F]{2})*))?$/i)

      # validate format
    when 'isbn'
      errors.add(:global_identifier, "Do not include 'ISBN'.") if (global_identifier =~ /isbn/i)
    when 'xref'
      if not (global_identifier =~ /\A.+\:.+/i)
        errors.add(:global_identifier, "Invalid format for an xref.")
      end
    when 'doi'
      errors.add(:global_identifier, "Do no include 'DOI'.") if (global_identifier =~ /DOI/i)
    end  

  end

  # This method is called from lib/model_extensions/has_standard_fields. 
  def update_cached_display_name # :yields: True
    current_id = $proj_id if !$proj_id.nil?
    $proj_id = self.proj_id
    if !self.identifier.blank? && !self.namespace.blank? # Method is fired pre-validation.
      namespace = self.namespace.short_name.blank? ? self.namespace.name : self.namespace.short_name # TODO: deprecate when all namespaces are updated to include short_name
      self.cached_display_name = "#{namespace} #{self.identifier}"
    else
      case global_identifier_type
      when 'uri', 'xref', 'lsid'
        self.cached_display_name = self.global_identifier
      when 'doi' 
        self.cached_display_name = "DOI:#{self.global_identifier}" # http://dx.doi.org/ 
      when 'isbn'
        self.cached_display_name = "ISBN:#{self.global_identifier}"
      else
        self.cached_display_name = "#{self.global_identifier_type} #{global_identifier}"
      end
    end
    $proj_id = current_id
    true # Continue the filter chain.
  end

  def display_name(options = {}) # :yields: String
    opt = {
      :type => nil 
    }.merge!(options.symbolize_keys)
    s = ''
    case opt[:type]
    when :list
      cached_display_name
    else
      cached_display_name
    end
    s
  end 

  def self.create_new(options = {}) # :yields: Identifier 
    # pass an Identifier {}, and the :object being identifier
    opt = {
      :addressable_id => options[:object].id,
      :addressable_type => options[:object].class.to_s
    }.merge!(options).to_options!

    return false if opt[:addressable_id].blank? || opt[:addressable_type].blank? || (opt[:identifier].blank? && opt[:global_identifier].blank?)

    opt.delete(:object)
    t = Identifier.new(opt)
    t.save 
    t 
  end  

  def identified_object # :yields: The object that the Identifier is attached to
    begin
      if ActiveRecord::const_get(self.addressable_type).respond_to?(:proj_id)
        ActiveRecord::const_get(self.addressable_type).find(self.addressable_id, :conditions => ["proj_id = ?", self.proj_id])
      else
        ActiveRecord::const_get(self.addressable_type).find(self.addressable_id)
      end
    rescue ActiveRecord::RecordNotFound
      false
    end
  end

  def self.rebuild_all
    Identifier.transaction do 
      Identifier.find(:all).each do |i|
        $proj_id = i.proj_id
        $person_id = i.updator_id
        i.save!
      end
    end
  end

end

