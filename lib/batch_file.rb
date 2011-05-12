# encoding: utf-8

class BatchFile
  attr_reader :headers, :rows
  
  # class that handles incoming text files
  def initialize(options = {})
    @opt = {
      :has_header_row => true,
      :check_headers => true,
      :legal_headers => [],
      :required_headers => []
    }.merge!(options)

  raise(ParseError,"No file/text provided") if !@opt[:file]
 
  if @opt[:file].class == String
    @rows = @opt[:file].split(/\r\n|\n|\r/)
  else
    @rows = @opt[:file].readlines
  end

  @headers = {}
  # get the headers
  heads = @rows.shift
  
  heads.split(/\t/).each_with_index do |r,i|
    @headers.update(r.downcase.to_sym => i) # reverse the hash for lookup purposes
  end

  # check the headers
  if @opt[:check_headers]
    @headers.keys.each do |h|
      raise(ParseError, "Column header '#{h}' not legal.") if !@opt[:legal_headers].include?(h)
    end
  end

    @rows = @rows.collect{|r| r.split(/\t/)}
  end

  def column_names
    @headers.keys.sort{|a,b| a.to_s <=> b.to_s}
  end

  def row_count
    @rows.size
  end

  # column is a symbol of a header or an integer
  def value_at_row_and_column(row, column_name) 
    @rows[row][@headers[column_name]]
  end

  def has_column(column)
    return true if self.column_names.include?(column)
    false
  end

class ParseError < StandardError
end





end
