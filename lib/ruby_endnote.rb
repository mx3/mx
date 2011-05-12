# encoding: utf-8
module RubyEndnote
  
  def self.parse_refs(options = {})
 	  @opt = {
      :txt => '' # required
    }.merge!(options)
    return false if (@opt[:txt].size == 0 )
    
    txt = @opt[:txt]
    refs = []

 	  e = txt.split(/\s*\n\s*\n/) # split on new endnote line double newline
    e.each do |r|
 	    refs << Endnote.new(:en => r)
	  end 
	    refs 
  end 

class Endnote

# there may be many more of these
# chr for DOI?

  attr :type                 #%O, Journal Article, Thesis, Book, Book Section
  attr :article_title        #%T
  attr :authors              #%A
  attr :editor               #%E
  attr :year                 #%D
  attr :book_title           #%B, title of book
  attr :journal_title        #%J
  attr :publisher            #%I
  attr :url                  #%U
  attr :pages                #%P
  attr :volume               #%V
  attr :number               #%N 
  attr :book_publisher       #%F 
  attr :publisher_location   #%C
  attr :summary              #%X
  attr :keywords             #%K
  attr :isbn                 #%@
  
  # parsed attributes 
  attr :pg_start
  attr :pg_end

 	def initialize(options = {})
 	  @opt = {
 	    :en => '' # incoming record
 	  }.merge!(options)
 	  
    return false if (@opt[:en].size == 0)

    @type = ''
	  @article_title = ''
	  @authors = []
 	  @editor = []
    @year = ''
    @book_title = ''
    @journal_title = ''
    @publisher = ''
    @url = ''
    @pages = ''
    @pg_start = ''
    @pg_end = ''
    @volume = ''
    @number = ''
    @book_publisher = ''
    @publisher_location = ''
    @summary = ''
    @keywords = ''
    @isbn = ''

    @opt[:en].split(/\n/).each do |line|
      next if line.nil?
      line.strip!
      v = line.split(/\s/, 2)               # splits on whitespace but limits to only one split 
      v[1].strip! if !v[1].nil?             # strip does chomp
      
      next if v[1].nil? # TODO: ADDED <- NOT CONFIRMED  

      case v[0]

      when '%T'
        @article_title << v[1]
      when '%A'
        @authors << v[1]
      when '%0'
        @type << v[1]
      when '%E'
        @editor << v[1]
      when '%D'
        @year << v[1]
      when '%B'
        @book_title << v[1]
      when '%J'
        @journal_title << v[1]
      when '%I'
        @publisher << v[1]
      when '%U'
        @url << v[1]
      when '%P'
        @pages << v[1]
        pages = v[1].split("-")
        @pg_start = pages.first
        @pg_end = pages.last
      when '%V'
        @volume << v[1]
      when '%N'
        @number << v[1]
      when '%F'
        @book_publisher << v[1]
      when '%C'
        @publisher_location << v[1]
      when '%X'
        @summary << v[1]
      when '%K'
        @keywords << v[1]
      when '%@'
        @isbn << v[1]
      end 
    end
  end 

  def authors_and_year
    #can do a lot more with this
	  @authors.join(", ") + ", " + @year
  end
  
  def pretty_journal_citation
    #can do a lot more with this
    @authors.join(", ") + "(" + @year + "). " + @article_title + ". " + @journal_title + ". " + @volume + ":" + @pages + "." 
  end

  end #end class
end #end module
