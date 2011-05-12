# encoding: utf-8
#== A module with string manipulation functions.  No mx-dependencies allowed. 

require 'toolbox/roman_numerals'

module Strings

  def self.unify_from_roman(string)
    return "" if string.nil?
    (self.is_int(string.to_s) || string.length == 0) ? string.to_s : string.upcase.to_i_roman.to_s
  end

  def self.scrub(string) # :yields: String
    # attempts to remove common issues with cut and pasted blocks
    str = string
    str.gsub!(/-[\s\n]*\n\s*/, '') # deal with hyphenated lines first
    str.gsub!(/\s+/, " ")
    linearize(str)
  end

  def self.linearize(string) # :yields: String
    string.gsub(/\n/, '').strip
  end

  # TODO: is this used anywhere? too convienient
  def self.remove_new_line(s) # :yields: String
    s.gsub(/\n/, '')
  end

  # is there another copy of this somewhere?
  def self.is_int(i) # :yields: true | false
    begin
      Integer(i)
      return true
    rescue ArgumentError
      return false
    end
  end

  def self.is_float(i) # :yields: true | false
    begin
      Float(i)
      return true
    rescue ArgumentError
      return false
    end
  end

  def self.split_on_words(text, min_word_size) # :yields: Array of Strings
    return [] if min_word_size == 0
    if min_word_size == 1
      text.strip.split(/\s*\b\s*/)
    else
      text.strip.split(/\s*\b[\w]{1,#{min_word_size - 1}}\b\s*/)
    end
  end

  def self.word_set_fusing_adjacent(options = {}) # :yields: Array of Strings
    opt = { 
      :incoming_text => "",           # Required. String of length > 0
      :adjacent_words_to_fuse => 1    # Required. Integer 
    }.merge!(options)
 
    return [] if opt[:incoming_text].size == 0 

    all_words = [] 
    (0..opt[:adjacent_words_to_fuse]).each do |i| 
      all_words += Strings::word_set(opt.merge!(:adjacent_words_to_fuse => i))
    end

    all_words.uniq
  end

  def self.word_set(options = {}) # :yields: Array of Strings
  # Returns an Array of words from a given string
    opt = { 
       :incoming_text => '',            # Required. String of length > 0
       :adjacent_words_to_fuse => 0,  # Required. Integer 
       :minimum_word_size => 1          # Required. Integer 
     }.merge!(options)
  
    return [] if opt[:incoming_text].length == '' 
    # convienience 
    t = opt[:incoming_text].clone
    return [] if !( t.class == String) || t.length == 0 
    
    # split the words, strip punctuation and whitespace
    # don't get words that span eliminated 
    
    wrds = []

    t.gsub!(/\-\s*\Z\s*/, '')                        # refuse dashes at the end of the line (should maybe not do this)
    t.split(/[\.\?\.\;\:]+/).each do |sentence| # we NEVER fuse terms across terminal and some punctuation (.?!;:)
      # eliminates small words by splitting on them and leaving an Array, we don't want to fuse words across fragments, when we're not fusing just split normally
      # this presently joins across commas
      if opt[:minimum_word_size] == 1
        fragments = [sentence]
      elsif opt[:minimum_word_size] > 1
        fragments = Strings::split_on_words(sentence, opt[:minimum_word_size]).reject{|w| w == "" || w == ","} 
      else
        raise
      end
    
      fragments.each do |fragment|
          tmp_wrds = fragment.split.map{|i| i.gsub(/[^A-Za-z\-\d\']/, '').strip.downcase}
          if opt[:adjacent_words_to_fuse] == 0
            wrds += tmp_wrds 
          else # fuse consecutive words
            if tmp_wrds.size >= opt[:adjacent_words_to_fuse] + 1 # we can fuse some words
              (0..(tmp_wrds.length - 1 - opt[:adjacent_words_to_fuse])).each do |i|
                wrds.push tmp_wrds[(i..(i + opt[:adjacent_words_to_fuse]))].join(" ")  
              end
            end
          end
        end # end fragment
    end # end fragments
    
    wrds.map{|w| w.strip}.uniq
  end

end
