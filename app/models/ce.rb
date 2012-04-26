require 'digest/md5'
require 'geokit'

include Geokit::Geocoders

class Ce < ActiveRecord::Base

  # CSS styles are in /class/ce.css and are listed by key
  LABEL_PRINT_STYLES = {
    :ce_lbl_insect_compressed => "4 pt insect label, compressed",
    :ce_lbl_insect => "4 pt insect label",
    :ce_lbl_4_dram_ETOH => "4 dram ETOH",
  }

  include ActionView::Helpers::TextHelper
  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods
  include ModelExtensions::Identifiable

  has_standard_fields

  belongs_to :geog
  belongs_to :namespace
  belongs_to :trip_namespace, :class_name => 'Namespace', :foreign_key => 'trip_namespace_id'
  belongs_to :locality_confidence, :class_name => 'Confidence', :foreign_key => 'locality_accuracy_confidence_id'
  belongs_to :georeference_protocol, :class_name => 'Protocol', :foreign_key => 'dc_georeference_protocol_id'

  has_many :public_tags, :as => :addressable, :class_name => "Tag", :include => [:keyword, :ref], :order => 'refs.cached_display_name ASC', :conditions => 'keywords.is_public = true'
  has_many :lots, :dependent => :nullify
  has_many :specimens, :dependent => :nullify
  has_many :ipt_records, :dependent => :nullify
  has_many :otus, :dependent => :nullify, :foreign_key => 'source_ce_id'

  scope :to_print, {:conditions => "ces.num_to_print > 0"}
  scope :with_verbatim_label, {:conditions => 'length(verbatim_label) > 0'}
  scope :without_geog, {:conditions => 'geog_id is null'}
  scope :without_lat_long, {:conditions => 'latitude is null and longitude is null'}
  scope :mappable, {:conditions => 'latitude is not null and longitude is not null'}
  scope :with_locality_accuracy_confidence_id, lambda {|*args| {:conditions => ["locality_accuracy_confidence_id = ?",  (args.first ? args.first : -1)]}}
  scope :with_macro_habitat, lambda {|*args| {:conditions => ["macro_habitat = ?",  (args.first ? args.first : -1)]}}
  scope :with_trip_namespace_id, lambda {|*args| {:conditions => ["trip_namespace_id = ?",  (args.first ? args.first : -1)]}}
  scope :with_locality_like, lambda {|*args| {:conditions => ["locality like ?",  (args.first ? "%#{args.first}%" : -1)]}}
  scope :excluding_id, lambda {|*args| {:conditions => ["ces.id != ?",  (args.first ? args.first : -1)]}}

  validates_numericality_of :latitude, :longitude, :allow_nil => true
  validates_format_of :time_start, :with => /\d\d:\d\d/, :allow_nil => true, :allow_blank => false
  validates_format_of :time_end,   :with => /\d\d:\d\d/, :allow_nil => true, :allow_blank => false

  before_save :validate_md5_uniqueness_for_non_nil_verbatim_labels

  def validate_md5_uniqueness_for_non_nil_verbatim_labels
    # reset the MD5
    if self.verbatim_label.blank?
      return true # always allow blank verbatim labels
    else
      data = Ce.generate_md5(self.verbatim_label)
    end

    if self.new_record?
      ce = Ce.present_via_md5?(data, self.proj_id)
    else
      ce = Ce.find(:first, :conditions => ["proj_id = ? AND verbatim_label_md5 = ? and id != ?", self.proj_id, data, self.id])
    end

    if ce # we've found a duplicate verbatim label
      errors.add(:verbatim_label, " is already present in the database")
      return false
    end

    self.verbatim_label_md5 = data
    true
  end

  def self.generate_md5(text)
    return nil if text.blank?
    Digest::MD5.hexdigest(text.gsub(/\s*/, '').downcase)
  end

  def update_md5
    self.verbatim_label_md5 = Ce.generate_md5(self.verbatim_label)
    self.save
  end

  def self.present_via_md5?(md5, proj_id)
    Ce.find(:first, :conditions => ["proj_id = ? AND verbatim_label_md5 = ?", proj_id, md5])
  end

  def display_name(options = {}) # :yields: String
    opt = {
      :type => :line
    }.merge!(options.symbolize_keys)
    s = ''

   case opt[:type]
     when :verbose
      s << verbatim_label.to_s
      if s.blank?
        s = self.display_name(:type => :verbose_material_examined_string)
      end
     when :verbose_material_examined_string
      s << [self.locality, self.verbatim_method, self.date_range, self.collectors].compact.reject(&:blank?).join(", ")
     when :for_select_list
       if verbatim_label.blank?
        s << (truncate(geography, :length => 20) + '<br />') if !geography.blank?
        s << (" " + truncate(locality, :length => 20) + '<br />') if !locality.blank?
        s << " " + date_range
        s << " " + truncate(collectors, :length => 20) if !collectors.nil?
        s << truncate(verbatim_label, :length => 45)  if ((s == '') && (verbatim_label != nil)) # if there is nothing in the label use verbatim label field
       else
         s << verbatim_label
       end
        s <<  " [id:" + id.to_s + "]"
     when :trip_code
        s << [self.trip_namespace.andand.name, self.trip_code].reject(&:blank?).join(" ")
     when :selected
        s << self.display_name(:type => :for_select_list)
     else
       if verbatim_label.blank?
        tmp_str = [geography, locality, lat_long, elevation, date_range, collectors, mthd, self.display_name(:type => :trip_code)].reject(&:blank?).collect{|t| truncate(t, :length => 45, :omission =>  '...')}.join(", ")
       else
        tmp_str = verbatim_label
       end

       s << "<div class=\"dn_#{opt[:type].to_s}\">"
       s << "<div class=\"dnsid\">id: #{id}</div>"
       # the label content
          s << '<span class="hd">ce: </span>' if opt[:type] == :sub_select
          # case views for :list, :head, etc. here
          # case opt[:type]
          # when :list
          s << '<div class="small_grey">'
          if tmp_str.blank? && verbatim_label.blank?
           s << "<span style=\"color: red;\">stub only</span>"
          elsif !verbatim_label.blank? && tmp_str.blank?
            s << verbatim_label
          else
           s << "#{tmp_str}"
          end
          s << "</div>"
          # end

        s << "</div>"
     end
    return "" if s == "" # mx3 was return nil
    s.html_safe
  end

  def start_day_of_year
    if !sd_d.blank? && !sd_m.blank? && !sd_y.blank?
      c = start_date.split(/\./)
      DateTime.civil(c[2].to_i,c[1].to_i,c[0].to_i, 0, 0, 0, 0).yday.to_i
    else
      nil
    end
  end

  def start_date
    [ Strings.unify_from_roman(sd_d), Strings.unify_from_roman(sd_m), Strings.unify_from_roman(sd_y)].reject(&:blank?).join(".")
  end

  def end_date
    [ Strings.unify_from_roman(ed_d), Strings.unify_from_roman(ed_m), Strings.unify_from_roman(ed_y)].reject(&:blank?).join(".")
  end

  def date_range # :yields: String for start and end dates
    dt = ""

    sd = Strings.unify_from_roman(sd_d)
    sm = Strings.unify_from_roman(sd_m)
    sy = Strings.unify_from_roman(sd_y)
    ed = Strings.unify_from_roman(ed_d)
    em = Strings.unify_from_roman(ed_m)
    ey = Strings.unify_from_roman(ed_y)

    return "" if sy.blank? && sm.blank? # can you have month alone?
    return self.start_date if (ed.blank? && em.blank? && ey.blank?)

    range = ''

    if sy==ey || ey.blank?
      if sd.blank? && ed.blank?
        return [sm,em].reject(&:blank?).uniq.join("-") + "." + sy
      end

      if sm == em # same month, same year
        range = [sd,ed].reject(&:blank?).join("-") + "." + sm + "." + sy
      else # different months, same year
        range =  sd + "." + sm + "-" + ed + "." + em + "." + sy
      end
    else # different years
      return (sy + "-" + ey) if sd.blank? && em.blank?
      if sd.blank? && ed.blank?
        range = sm + "." + sy + "-" + em + "." + ey
      else
        range = self.start_date + "-" + self.end_date
      end
    end

    range.gsub(/(\A[\.\-])|(\z[\.\-])/, '')
  end

  def lat_long # :yields: String representing lat/long
    ll = ''
    if latitude
      ll = latitude.to_s + ( latitude.to_f < 0 ? 'S' : 'N' ) + ", " + longitude.to_s  + (longitude.to_f < 0 ? 'W' : 'E')
    end
    ll
  end

  def elevation(units = 'meters') # :yeilds: String representing elevation range, valid units are 'meters' and 'feet'
    rng = []
    return "" if elev_min.blank? && elev_max.blank?
    if units == elev_unit
      rng = [elev_min, elev_max]
    else # doesn't match, convert
      if units == 'meters' # convert to meters
        rng  = [ '%.2f' %  elev_min.to_f.meters.to.feet.to_s, (elev_max.blank? ? nil : '%.2f' % elev_max.to_f.meters.to.feet.to_s) ]
      elsif units == 'feet' # convert to feet
        rng  = ['%.2f' % elev_min.to_f.feet.to.meters.to_s, (elev_max.blank? ? nil : '%.2f' % elev_max.to_f.feet.to.meters.to_s) ]
      else
        return 'error'
      end
    end
    rng = [rng[0]] if rng[0] == rng[1]
    str = rng.reject(&:blank?).join('-')
    str.blank? ? "" : str + " #{units}"
  end

  def convert_elevation(min_or_max, units)
    case min_or_max
    when 'min'
      v = elev_min
    when 'max'
      v = elev_max
    else
      return nil
    end
    return v if units == elev_unit
    return nil if v.blank?
    v.send(elev_unit).to.units
  end

  def mappable # :yields: True | False
    return true if !latitude.blank? && !longitude.blank?
    false
  end

  def gmap_hash # :yields: Hash
    if self.mappable
      # name should be description, to match up
      # need better character escaping here
      {:latitude => self.latitude, :longitude => self.longitude, :name => self.display_name(:type => :summary).gsub(/[\r\n|\n|\r]/, '<br />').gsub(/\'/, "&#39;")} # cross platform newlines STILL SUCK, even in Ruby AFAIKT
    else
      false
    end
  end

  # puts the hash in an array, so we can use it as a single marker
  def gmap_array
    [gmap_hash]
  end

  def geog_array
    return [nil, nil, nil, nil] if self.geog.blank?
    [self.geog.country_string, self.geog.state_string, self.geog.county_string, self.locality]
  end

  def self.new_from_geocoder(params = {})
    res = GoogleGeocoder.reverse_geocode([params[:lat].to_f, params[:long].to_f])
    if res.success
      Ce.new(
             :locality => res.full_address,
             :geog => Geog.detect_from_geocode(res),
             :latitude => res.lat,
             :longitude => res.lng
            )
    else
      Ce.new(
             :verbatim_label => 'Geocoding failed.'
            )
    end
  end

  # TODO: derive
  def self.convert_to_decimal_degrees(options = {})
    opt = {
      :literal => nil,  # try and guess the lat long
      :degrees => 0,
      :minutes => 0,
      :seconds => 0
     }.merge!(options.symbolize_keys)
  end

  # TODO: move this to a utilities/admin module
  # Console calls only.
  def self.regenerate_all_md5s
    Ce.transaction do
      begin
        # puts "updating: "
        Ce.find(:all).each do |c|
        #  puts c.id
          $proj_id = c.proj_id
          c.update_md5
        end
      rescue ActiveRecord::RecordInvalid => e
        raise "Unable to complete update: #{e}"
      end
    end
    true
  end

  # As in Specimen batch loading - '++' = '\n\n', '||' => '\n'
  def self.from_text(text)
    text.split(/\n{2,}/m).map {|x| x.strip.gsub(/\|\|/, "\n").gsub(/\+\+/, "\n\n") + "\n"}
  end

  def end_time # :yields: string, time only (db stores dummy date)
    [time_end.andand.hour, time_end.andand.min].compact.join(":")
  end

  def start_time # :yields: string, time only (db stores dummy date)
    [time_start.andand.hour, time_start.andand.min].compact.join(":")
  end

  def self.find_for_auto_complete(value)
    conditions = value.split.collect { |t|
      sanitize_sql(["((c.verbatim_label like ?) OR
                   (c.geography like ?) OR
                   (c.locality like ?) OR
                   (c.trip_code like ?) OR
                   (g.name like ?) OR
                   (c.id = ?) OR
                   co.name like ? OR
                   st.name like ? OR
                   con.name like ? OR
                   c.collectors LIKE ?)",
        "%#{t}%", "%#{t}%", "%#{t}%", "%#{t}%", "#{t}%", "#{t}", "%#{t}%","%#{t}%", "%#{t}%", "%#{t}%"])
    }.join " AND "

    find_by_sql("SELECT c.* FROM ces c
                    LEFT JOIN geogs g ON c.geog_id = g.id
                    LEFT JOIN geogs co ON g.country_id = co.id
                    LEFT JOIN geogs st ON g.state_id = st.id
                    LEFT JOIN geogs con ON g.county_id = con.id
                    WHERE c.proj_id = #{$proj_id} AND #{conditions} LIMIT 30")
  end

  protected

  validate :check_record
  def check_record
    if latitude
      errors.add(:latitude, "must be within -90 to 90") unless (-90 <= latitude.to_f and latitude.to_f <= 90)
    end
    if longitude
      errors.add(:longitude, "must be within -180 to 180") unless (-180 <= longitude.to_f and longitude.to_f <= 180)
    end
    errors.add(:latitude, 'Both latitude and longitude need to be added if one or the other is present.') if ((!latitude.blank? && longitude.blank?) || (!longitude.blank? && latitude.blank?))
    errors.add(:sd_m, "must provide a starting month if starting day is provided") if  !sd_d.blank? && sd_m.blank?
    errors.add(:ed_m, "must provide a starting month if ending day is provided") if !ed_d.blank? && ed_m.blank?
  end

  # batch uploading
  def path_to_file
  end
end
