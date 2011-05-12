class Phenotype < ActiveRecord::Base
  
  belongs_to :entity, :polymorphic => true
  has_one :chr_state
  
  def self.kinds
    {"Presence/Absence" => "PresenceAbsencePhenotype", "Count" => "CountPhenotype", "Qualitative" => "QualitativePhenotype", "Relative measurement" => "RelativePhenotype"}
  end
  
  def display_label
    self.entity.label
  end
  
  private
  def term_label(term, html = false)
    if term.kind_of? OntologyTerm
      html ? %'<a href="#{term.uri}">#{term.label}</a>' : term.label
    elsif term.kind_of? OntologyComposition
      #TODO this is incomplete
      html ? %'<a href="#{term.genus.uri}">#{term.genus.label}</a>' : term.genus
    end
  end
  
end