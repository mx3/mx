class IptRecord < ActiveRecord::Base

  # IptRecord is a write rarely read often table with read/write handled through the ipt module (lib/ipt.rb).
  # Individual attributes must not be edited.

  set_table_name 'ipt_records'

  belongs_to :proj
  belongs_to :specimen
  belongs_to :lot
  belongs_to :geog, :foreign_key => :ce_geog_id
  belongs_to :ce
  belongs_to :taxon_name
  belongs_to :otu

  validates_presence_of :occurrence_id, :basis_of_record, :institution_code, :collection_code, :catalog_number, :scientific_name, :proj_id, :ce_id, :taxon_name_id, :otu_id
  validates_uniqueness_of :occurrence_id

  validate :check_record
  def check_record
    if specimen_id.blank? && lot_id.blank?
      self.errors.add(:specimen_id, 'Provide a specimen_id or lot_id')
    end
  end

  # See also Proj/table_csv_string
  def self.table_csv_string(options = {})
    opt = {
      :header_row => true,
      :conditions => '' 
    }.merge!(options)
    str = ''
   
    cols = IptRecord.columns.map(&:name)
    cols_str = cols.join(", ")
    sql = "SELECT #{cols_str} FROM ipt_records" 
    sql << " WHERE #{opt[:conditions]}"

    str << cols.join("\t") if opt[:header_row]
    str << "\n"

    ActiveRecord::Base.connection.select_rows(sql).each do |row| 
      # not filtering for tab characters here, likely should
      str << row.collect{|c| c == nil ? nil : c.gsub(/\n|\r\n|\r/, '\n')}.join("\t") + "\n"
    end
    str
  end


end
