class ExtractsGene < ActiveRecord::Base
  has_standard_fields

  belongs_to :gene
  belongs_to :confidence
  belongs_to :extract 

  validates_presence_of :gene_id, :extract_id, :confidence_id
 # validates_uniqueness_of :gene_id, :extract_id, :confidence_id

  def display_name(options = {})
    opt = {}.merge!(options)
    case opt[:type]
    when :status
      self.confidence.display_name(:type => :short)
    else
      self.confidence.display_name
    end
  end

end
