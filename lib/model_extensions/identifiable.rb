module ModelExtensions
  module Identifiable
    # include Identifiable in the Model

    def self.included(base)
      base.class_eval do

        tn = self.table_name                        # like otus
        cn = self.table_name.singularize.capitalize # like Otu

        has_many :identifiers, :as => :addressable, :dependent => :destroy, :before_add => :validate_identifier
        has_many :identifier_namespaces, :through => :identifiers, :source => :namespace

        scope :with_identifier, lambda {|*args| {:include => [:identifiers], :conditions => ["identifiers.identifier = ?", (args.first || -1)]}  }
        scope :with_global_identifier, lambda {|*args| {:include => [:identifiers], :conditions => ["identifiers.global_identifier = ?", (args.first || -1)]}  }
        scope :include_identifiers, :include => [:identifiers => :namespace]

        def validate_identifier
          if !identifier.valid? 
            errors.add(:base, "Identifier invalid.")
            raise ActiveRecord::RecordInvalid, self
          end
        end

      end # end class_eval
    end

  end
end
