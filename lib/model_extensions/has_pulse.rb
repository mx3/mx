module ModelExtensions

  module HasPulse

    def self.included(base)
      base.extend(MoreClassMethods)
    end

    module MoreClassMethods
      def has_pulse(options = {})
        return true if !self.table_exists? # don't run this on migrations   

        class_eval <<-EOV
        has_many :beats, :as => :addressable, :dependent => :nullify
        after_create :create_a_create_beat # TODO: add Proc if
        after_update :create_an_update_beat
      EOV

        send :include, InstanceMethods 
      end 
    end

    module InstanceMethods
      def create_a_create_beat 
        Beat.create!(:addressable_id => self.id,
                     :addressable_type => self.class.to_s,
                     :message => ( self.respond_to?(:create_beat_message) ? self.beat_create_message : "Someone created a #{self.class.name}.") )
      end

      def create_an_update_beat 
        Beat.create!(
                     :addressable_id => self.id,
                     :addressable_type => self.class.to_s,
                     :message =>  ( self.respond_to?(:update_beat_message) ? self.update_beat_message : "Someone updated a #{self.class.name}"  )
                    )
      end
    end
    # opt = {
    #   :propigate_to => [],
    #   :message => '',
    #   :propigate_on_create => true,
    #   :propigate_on_update => true
    # }.merge!(options)

    # opt[:propigate_to].each do |model|
    # end

  end
  # ActiveRecord::Base.send(:include, ModelExtensions::HasPulse)
end
