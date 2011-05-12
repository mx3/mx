# encoding: utf-8
# a utility class used in batch loading multiple Terms
module Turms
  class Turms
    attr_reader :not_present, :existing 
    def initialize()
      @not_present = []
      @existing = []
    end
  end

  class Turm
    attr_accessor :part, :term, :word, :definition
    def initialize(obj)
      if obj.is_a?(Part)
        @part = obj
      else
        @term = obj
      end
    end

    def word
      if self.part
        self.part.name
      else
        self.term
      end
    end
  end
 
 # TODO not used? 
  class Relationship
    attr_reader :parent, :child
    def initialize(obj)
    end
  end
  
end
