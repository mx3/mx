# encoding: utf-8
class Linker

  # A utility class that matches words in a block of text to Labels/OntologyClasses in mx

  require 'Strings'

  attr_reader :all_words          # Array of all individual words
  attr_reader :link_root
  attr_reader :proj_id
  attr_reader :link_url_base      # replaces :public_server_name, the server_name to reference when creating links
  # attr_reader :public_server_name # Proj#public_server_name # DEPRECATED
  attr_reader :text_to_link 
  attr_reader :proj           

  def initialize(options = {}) # :yields: Linker (instance)
    opt = {
      :incoming_text => nil,                                # REQUIRED not nil
      :proj_id => nil,                                      # REQUIRED not nil, the project containing the "ontology" and plural keyword(s)
      :match_type => :predicted,                            # REQUIRED not nil, :predicted => break down text and match, :exact => attempt to match all possible labels against the string
      :scrub_incoming => false,                             # Attempt whitespace and hyphenated word cleanup.
      :is_public => false,                                  # if true then edit/internal linkages are not displayed
      :exclude_common_words => false,                       # subtracts COMMON_WORDS from @all_words on init,                                   IGNORED when :match_type => :literal
      :exclude_common_words_of_size_smaller_than => 99999,  # if exclude_common_words is true then only exclude COMMON_WORDS of length < this,  IGNORED when :match_type => :literal
      :common_words => COMMON_WORDS,                        # COMMON_WORDS is in /lib, a custom list can be provided, see also terms counts,    IGNORED when :match_type => :literal
      :minimum_word_size => 1,                              # exclude from @all_words words smaller than this,                                  IGNORED when :match_type => :literal
      :adjacent_words_to_fuse => 0,                         # e.g. given "A B C" and 2 (n-1) then @all_words is [A, A B, B C, A B C],           IGNORED when :match_type => :literal
      :link_url_base => ''
    }.merge!(options)

    # default values are configured here
    @text_to_link = ""
    @all_words = []

    self.reset!(opt)
    return self
  end

  def reset!(options = {}) # :yields: Boolean
    opt = {}.merge!(options)

    # don't let a reset happen if there is nothing to work with, just return an "empty" object 
    return false if !opt[:incoming_text] || (opt[:incoming_text].size == 0) || opt[:proj_id].blank?

    @proj_id = opt[:proj_id]
    @proj = Proj.find(@proj_id)

    # set the accessible vars
    # @public_server_name = @proj.ontology_server_name 

    if opt[:scrub_incoming]
      @text_to_link  = Strings::scrub(opt[:incoming_text]) 
    else
      @text_to_link = opt[:incoming_text]
    end 
    
    @link_url_base = opt[:link_url_base] 

    @all_words = []
    case opt[:match_type]
    when :predicted 
      @all_words = Strings::word_set_fusing_adjacent(opt)
    when :exact
      tmp_txt = Strings::scrub(opt[:incoming_text])
      @proj.labels.with_definitions.ordered_by_name.each do |l|
        @all_words.push(l.name) if (tmp_txt =~ /\b#{l.name}\b/i)
      end
    end

    @link_root = (opt[:is_public] ? "http://#{@link_url_base}/projects/#{@proj_id.to_s}/public" : "/projects/#{@proj_id.to_s}") # was @public_server_name

    # exclude common words if requested 
    # we could consider using prefix trees if they would speed things up, see: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/226837
    if opt[:exclude_common_words]
      # @all_words = @all_words - opt[:common_words] # TODO: benchmark this approach vs. below 
      rgx = Regexp.new(opt[:common_words].collect{|w| "\\b(?:#{w})\\b"}.join("|")) # compile one giant regex to match against, should be faster than double loop
      @all_words.reject!{|w| w =~ rgx}
    end 

    true
  end

  # render HTML linkages
  def linked_text(options = {}) # :yields: String (HTMLized text)
    opt = {
      :popup => false,
      :css_class => 'passed',
      :min_length => 1,
      :mode => 'mx_link'               # 'mx_link' (render in mx application) |'bracket' | 'bioportal_uri_link' (bioportal URI) | 'api_link' (back to mx api) 
    }.merge!(options)

    # some defaults if @text_to_link is not set
    return '<em>none</em>'.html_safe if @text_to_link == "" || @text_to_link.empty?
    return '<em>configuration error</em>'.html_safe if (opt[:is_public] && @link_url_base.blank?) 

    # set root for various links
    case opt[:mode]
    when 'mx_link'
      lnk_root = @link_root
    when 'api_link'
      return 'api not configured' if @proj.api_name.blank?
      lnk_root = "http://#{@proj.api_name}/ontology"
    when 'bioportal_uri_link'
      lnk_root = "http://purl.obolibrary.org/obo"
    end

    out =  @text_to_link

    # Popup link in new window?
    popup_txt = (opt[:popup] ? 'target="_blank"' : '')       

    # Generate a Hash of Arrays like "foo" => [1,2] where keys are Label names and values are Arrays of OntologyClass#id 
    matchable_words = self.matchable_words(opt) 

    # Sort longest to shortest to prevent nested matches
    matchable_words.keys.sort{|x, y| y.size <=> x.size}.each do |w| 
      link, a,b,c = ['', '', '', '']

      case opt[:mode]
      when 'mx_link',  'bioportal_uri_link', 'api_link'
        if matchable_words[w].size == 1 # a single definition for the word (not a homonym in the ontology)
          next if matchable_words[w].first.xref.blank? && ["bioportal_uri_link", "api_link"].include?(opt[:mode])
          case opt[:mode]
          when 'mx_link'  
            link = "<notextile><a class=\"#{opt[:css_class]}\" #{popup_txt} href=\"QQQQ/ontology_class/show/#{matchable_words[w].first.id.to_s}\">#{w}</a></notextile>"
          when 'bioportal_uri_link'
            link = "<a #{popup_txt} href=\"QQQQ/#{matchable_words[w].first.xref.gsub(/:/,"_")}\">#{w}</a>"
          when 'api_link'
            link = "<a #{popup_txt} href=\"QQQQ/ontology_class/#{matchable_words[w].first.xref.gsub(/:/,"_")}\">#{w}</a>"
          end

        elsif matchable_words[w].size >  1
          case opt[:mode]
          when 'mx_link' 
            link = "<notextile><a class=\"failed\" #{popup_txt} href=\"QQQQ/label/show_via_name/#{w}\">#{w}</a></notextile>"  # matchable_words[w].first.to_s
          when 'bioportal_uri_link' 
            # only link to those classes with a xref (if any)
            linx = []
            i = 1
            # generate multiple links like 'word (_1_,_2_,_3_)'
            matchable_words[w].each do |oc|
              if !oc.xref.blank?
                linx.push( "<a #{popup_txt} href=\"QQQQ/#{oc.xref.gsub(/:/,"_")}\">#{i}</a>" ) 
                i += 1
              end
            end
            next if linx.size == 0
            link = "#{w} (" + linx.join(", ") + ")"

          when 'api_link'
            # we use a different method ('label') here rather than mutliple links
            link = "<a #{popup_txt} href=\"QQQQ/ontology/label/#{w}\">#{w}</a>" 
          end
      
      else
        next
      end

      # thanks Phrogz @ http://bit.ly/i8Tcqj
      brackets = []
      a = out.gsub( /<a.*?>(.*?)<\/a>/){ |b| brackets << b; "-^#{brackets.length-1}^-" }
      b = a.gsub(/\b#{w}\b/i) {|s| link }

      when 'bracket'
        brackets = []
        a = out.gsub( /\[[^\]]+\]/ ){ |b| brackets << b; "-^#{brackets.length-1}^-" }
        b = a.gsub(/\b#{w}\b/i) {|s| "[#{w}]" }
      end 

      c = b.gsub( /-\^\d+?\^-/i ){ |s| brackets[ s[/\d+/].to_i ] }
      out = c

    end

    # some cleanup/final checking
    out.gsub!(/QQQQ/, lnk_root) if out.size > 0 && opt[:mode] != 'bracket' # gets rid of the problem of the link_root having a defined word in it, rare, but possible
    out.gsub!(/\n/, '<br />') if opt[:mode] == 'mx_link'
    out.strip.html_safe
  end

  def link_set(options = {}) # :yields: Array (of Labels)
    # default allows Labels not tied to OntologyClasses (i.e. without definitions)
    # returns ALL possible links in the text
    opt = {
      :exclude_blank_descriptions => false,
      :include_plural => true,               # also attempt to match on plural form Tags of Parts
      :min_length => 1,                      # only include Parts with name greater than min_length
      :result_type => :all                   # :all => all, :homonyms => those with 2 or more OntologyClasses, :synonyms => :labels that are synonyms
      # may need a max_words cuttoff here 
    }.merge!(options)

    return [] if @all_words == [] || @all_words == nil 

    tmp_words = @all_words.reject{|w| w.length < opt[:min_length]}

    case opt[:result_type]
    when :all
      if opt[:exclude_blank_descriptions]
        @proj.labels.with_definitions.with_label_from_array(tmp_words).ordered_by_label_length.ordered_by_name 
      else
        @proj.labels.with_label_from_array(tmp_words).ordered_by_label_length.ordered_by_name 
      end
    when :homonyms
      # :homonyms never have blank definitions (by definition)
      @proj.labels.with_label_from_array(tmp_words).ordered_by_label_length.ordered_by_name.that_are_homonyms
    when :synonyms
      @proj.labels.with_label_from_array(tmp_words).ordered_by_label_length.ordered_by_name.that_are_synonyms
    else
      @proj.labels.with_label_from_array(tmp_words).ordered_by_label_length.ordered_by_name 
    end
  end

  def unmatched(options ={}) # :yields: Array (of strings)
    opt = {
      :minimum_word_size => 1 # return only words of size length, can be different than on init
    }.merge!(options)
    return [] if @all_words.size == 0
    matchable_words = self.link_set(opt).inject([]){|sum, p| sum += p.all_forms}
    # this is word in any, we want exact matches 
    # rgx = Regexp.new( matchable_words.collect{|w| "\\b(?:#{w})\\b"}.join("|") ) # compile one giant regex to match against, should be faster than double loop
    (@all_words - matchable_words).reject{|w| w.length < opt[:minimum_word_size]}.sort{|a,b| (b.length <=> a.length) && (a <=> b)}
  end

  def matchable_words(options = {}) # :yields: Hash {String => Array}, e.g. {'label1' => [OntologyClass ...], 'label2' => [OntologyClass ... ]}  
    opt = {
    }.merge!(options)
    mws = {}
    self.link_set(opt).each do |l|
      mws.merge!(l.name => OntologyClass.by_proj(@proj_id).by_label_including_plurals(l.name).uniq )
    end
    mws  
  end

  def matchable_ontology_classes(options = {}) # :yields: Array of OntologyClasses
    opt = {}.merge!(options) 
    link_set(opt).inject([]){|sum, a| sum += a.ontology_classes}.uniq
  end

  def tab_file(options = {}) # :yields: String representation of a tab file
    opt = {}.merge!(options) 

    rows = [['label', 'concept', 'URI']]

    link_set(opt).sort{|a,b| a.name <=> b.name}.each do |l|

      row_head = l.display_name

      l.ontology_classes.each do |oc| 
        class_head = oc.display_name
        uri =  Ontology::OntologyMethods.obo_uri(oc)

        if row_head
          rows.push [row_head, class_head.gsub(/\t/, '').gsub("\n",''), uri]
          row_head = false
        else
          rows.push ["", class_head, uri]
        end 
      end
    end

    rows.collect{|columns| columns.join("\t")}.join("\n")
  end


end

