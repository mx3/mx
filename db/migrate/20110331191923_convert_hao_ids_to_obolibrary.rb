class ConvertHaoIdsToObolibrary < ActiveRecord::Migration
  def self.up
    begin
      OntologyTerm.transaction do
        OntologyTerm.find(:all).each do |term|
          old_uri = term.uri
          term.uri = old_uri.gsub(/http:\/\/purl.org\/obo\/owl\/HAO#/, 'http://purl.obolibrary.org/obo/')
          term.save
        end
      end
    rescue
      raise
    end
  end

  def self.down
    # no need to go back
  end
end
