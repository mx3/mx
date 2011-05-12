module ModelExtensions
  module Figurable 
    # 'include Figurable' in the model to use
    # model must have an id column

    def self.included(base)
      base.class_eval do
        has_many :figure_markers, :through => :figures
        has_many :figures, :as => :addressable, :dependent => :destroy,  :order => :position
        has_many :images, :through => :figures 
      end 
    end
  end
end
