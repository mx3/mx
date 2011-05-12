module ModelExtensions
  module MiscMethods

    # inside the model include: 
    # include ModelExtensions::MiscMethods 

    # can get this in controllers, but not models where we explicitly use it in rare cases
    def self.host_url
      case RAILS_ENV
      when 'development' || 'test'
     'http://127.0.0.1:3000'
      when 'production'
     "http://#{HOME_SERVER}"
      else
        raise
      end
    end

    def self.included(base)

      base.class_eval do

        tn = self.table_name                        # like otus
        cn = self.table_name.singularize.capitalize # like Otu

        def self.random(proj_id, in_public = false)
          raise "self.random called with is_public == true on Class without is_public column" if in_public && !self.columns.map(&:name).include?('is_public') 
          if in_public 
            objs = self.is_public.find(:all, :conditions => "proj_id = #{proj_id}")
          else
            objs = self.find(:all, :conditions => "proj_id = #{proj_id}")
          end
          objs[rand(objs.size)]
        end

        protected 
        # Warning: This is a dangerous method, it needs review
        def self.clone_from_project(from_proj) # assumes legal proj has been checked already, fails nicely (won't dupe)
          c = 0
          if proj = Proj.find(from_proj)
            # TODO: check that a has_many_actually exists
            proj.send(self.name.downcase.pluralize).each do |o|
              clone = o.clone # proj/creator etc. are set automagically!
              c += 1 if clone.save
            end
          end
          return c 
        end

      end # end class_eval

    end
  end
end
