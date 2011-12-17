module ModelExtensions

module HasStandardFields

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def has_standard_fields
      return true if !self.table_exists? # don't run this on migrations
      class_eval <<-EOV
          # ASSOCIATIONS

          column_names = self.columns.collect{|c| c.name }

          belongs_to(:creator, :class_name => 'Person', :foreign_key => 'creator_id') if column_names.include?("creator_id")
          belongs_to(:updator, :class_name => 'Person', :foreign_key => 'updator_id') if column_names.include?("updator_id")
          belongs_to(:proj) if column_names.include?("proj_id")

          #== MAGIC FIELD CALLBACKS
          #before_validation :call_update_cached_display_name, :set_updator
          before_validation(:on => :update) do
            # Maintain order of calls.
            set_updator
            call_update_cached_display_name
          end

          #before_validation_on_create :set_creator, :set_proj # called before validation so proj_id can be used in validate
          before_validation(:on => :create) do
            # Maintain order of calls.
            set_creator
            set_updator
            set_proj
            call_update_cached_display_name
          end

          # each model defines its own update_cached_display_name method
          def call_update_cached_display_name
            update_cached_display_name if self.respond_to?(:update_cached_display_name)
          end

          def set_creator
            self[:creator_id] = $person_id if self.respond_to?(:creator_id) && self.creator_id.blank? # tweaked - don't override if given (script load)
          end

          def set_proj
            # modified below to not set proj_id when proj not set
            self[:proj_id] = $proj_id if self.respond_to?(:proj_id)
          end

          def set_updator
            self[:updator_id] = $person_id if self.respond_to?(:updator_id) && (self.new_record? ? self.updator_id.blank? : true)
          end

          #== PROJECT SECURITY CALLBACKS
          # security measure to prevent people from altering data in other projects.
          # the user has already been authenticated as a member of $proj_id, so we just check the id on the object
          before_save :check_proj
          before_destroy :check_proj

          def check_proj
            if self.respond_to?(:proj_id) && !$merge == true
               unless (self.proj_id == $proj_id) or ((self.proj_id == nil) and (Person.find($person_id).is_admin == true))
                 raise "Not owned by current project: " + self.class.name + "#" + self.id.to_s
               end
            end
            true
          end

          #== SHORT INFORMATION METHODS
          def c_on
            self.created_on.strftime("%m/%d/%Y") if self.respond_to?(:created_on) and self.created_on
          end

          def m_on
            self.updated_on.strftime("%m/%d/%Y") if self.respond_to?(:updated_on) and self.updated_on
          end

          def c_by
            self.creator.name if self.respond_to?(:creator) and self.creator
          end

          def m_by
            self.updator.name if self.respond_to?(:updator) and self.updator
          end

          def taggable
            true if self.respond_to?(:id) and self.id
          end






         EOV

    end
  end

end
end
