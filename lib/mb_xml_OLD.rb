# encoding: utf-8
class Mb_xml

 # http://morphbank.net/schema/API1.html

  # all camelcase constansts are like firstResult parameters in MB, and FIRST_RESULT here, otherwise they are like 'objecttype', and 'OJBECTYPE' here
  
  # some "constants" (defaults really)
  SEARCH_URL =  'http://services.morphbank.net/mb2/request?' 
  LIMIT = 8
  METHOD = 'search' 
  FORMAT = 'id'
  DEPTH = 1
  OBJECTTYPE = 'Image'
  FIRST_RESULT = 0
 
  # incoming options (might not need this)
  attr :opt, true
  attr :keywords, true
  
  # created
  attr :search_url, true # ours, not their response
  
  # created from response
  attr_reader(:xml_data, :doc, :root, :num_results, :num_results_returned, :first_result)
  
  # all the objects returned
  attr :objects, true
  attr :ids, true

  # individual collections of specific object types (likely eliminate here)
  attr :annotations
  attr :images

 def initialize(keywords, options = {}) # called on creation
   # allow for more params here...
   @keywords = keywords
   @opt = {
      :limit => LIMIT,
      :method => METHOD,
      :format => FORMAT,
      :depth => DEPTH,
      :objecttype => OBJECTTYPE,
      :first_result => FIRST_RESULT
   }.merge!(options)
   
   # keywords is a string
   @keywords.gsub!(/\s/, '%20')   # quick and dirty for now

   @search_url = SEARCH_URL + 
      'method=' + @opt[:method] +
      '&keywords=' + @keywords + 
      '&objecttype=' + @opt[:objecttype] + 
      '&firstResult=' + @opt[:first_result].to_s + 
      '&limit=' + @opt[:limit].to_s + 
      '&format=' + @opt[:format]

   # http://services.morphbank.net/mb2/request?method=search&objecttype=Image&keywords=Apoidea&limit=10&firstResult=0&user=&group=&change=&lastDateChanged=&numChangeDays=1&id=&taxonName=&format=id
   # presently using the id method for searching morphbank (@ids). Best to use XML using schema.
   
   @xml_data = Net::HTTP.get_response(URI.parse(@search_url)).body
   @doc = REXML::Document.new(@xml_data)
   #   REXML::XPath.first(self.xml, \"#{e.name.to_s}).text\").text
   @opt[:first_result] = REXML::XPath.first(@doc, "//firstResult").text
   @opt[:num_results_returned] = REXML::XPath.first(@doc, "//numResultsReturned").text
   @opt[:num_results] = REXML::XPath.first(@doc, "//numResults").text #these are not public so not returned via present morp
   
   @objects = REXML::XPath.match(@doc, "//method").collect{|o| Mb_obj.new(o)}
   @ids = REXML::XPath.match(@doc, "//id").collect{|i| Mb_obj.new(i).ids_only}
 end

 # pagination for objects
 def lnk_fwd
    if  (self.opt[:num_results_returned].to_i + self.opt[:first_result].to_i) < self.opt[:num_results].to_i
       return true
    end
   false
 end

 def lnk_bck
    if self.opt[:first_result].to_i > LIMIT
       return true
    end
   false
 end

end

#offest

# http://services.morphbank.net/mb3/request?objecttype=Image&id=195815&format=svc
# http://services.morphbank.net/mb3/request?method=id&objecttype=Image&id=195815&format=svc

class Mb_obj
  attr :xml, true # the xml we derived this object from

  # the basic XML methods returned
  # [:objectTypeId, :description, :thumbURL,:dateCreated, :dateLastModified, :dateToPublish]
  # thumbURL is no longer a URL, its just an ID

  def initialize(o)
    @xml = o
    
    # map element names to methods, prolly not the best way to do this
    @xml.elements.each do |e|
     Mb_obj.class_eval("def #{e.name.to_s}() REXML::XPath.first(self.xml, \"#{e.name.to_s}).text\").text end") 	 
    end
  end

  def ids_only
    self.xml.text
  end
  
  def elements
    self.xml.elements
  end
  
  # keywords is itself a XML doc
  def kw_element_txt(element)
    REXML::XPath.match(
      REXML::Document.new( REXML::XPath.first(self.xml, "keywords").text ),
      "//#{element}").first.text 
  end

end

