# encoding: utf-8
# a utility class used in batch loading multiple Refs 
# uses the #new_record? from Rails

module Rephs
  class Rephs
    attr_reader :rephs

    def initialize()
      @rephs = []     # store the Reph
    end

    def unmatched_rephs
      @rephs.reject{|reph| !(reph.ref != nil && reph.ref.new_record?) }
    end

    def matched_rephs
      @rephs.reject{|reph| !(reph.ref != nil && !reph.ref.new_record?) }
    end

    def unmatched_serials
      @rephs.reject{|reph| !(reph.ref != nil && !reph.ref.serial.blank? && reph.ref.serial.new_record?)}.uniq.collect{|r| r.ref.serial}
    end

    def matched_serials
      @rephs.reject{|reph| !(reph.ref != nil && !reph.ref.serial.blank? && !reph.ref.serial.new_record?)}.uniq.collect{|r| r.ref.serial}
    end

    def saved_rephs
      @rephs.reject{|reph| !reph.saved?}
    end

  end

  class Reph
    attr_accessor :ref, :reph,  :ref_authors, :ref_editors, :saved
    def initialize(reph, ref)
      @reph = reph # the incoming Endnote object
      @ref = ref   # the matching translation (in this case an mx Ref, but could be other)
      @ref_authors = [] # mx Authors
      @ref_editor  = [] # mx Authors 
      @saved = false
    end
  
    def saved?
      @saved
    end

  end
 
  
end
