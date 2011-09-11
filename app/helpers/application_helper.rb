# encoding: utf-8
module ApplicationHelper

  # Methods added to this helper are available to all templates in the application.
  
  # Helpers have been split out
  # if you share methods add the pertinent model to the helper Array in application.rb

  # borrowed from http://www.nervetree.com/2007/12/24/how-random-is-random-ruby-on-rails-uuids
  def uuid()
     sql = "SELECT UUID()"   
     record = ActiveRecord::Base.connection.select_one(sql)
     record['UUID()']
  end

  # returns true if object is created by logged in user or  user is admin
  # TODO: move to plugin/shared code or filters
  def created_or_admin(obj)
    if session[:person].id.to_i == obj.creator_id.to_i || session[:person].is_admin
      true
    else
      false
    end
  end
 
  # returns an active record object by type and id, usefull for addressable object (not working? type conversion?)
  # def obj_by_type(type, id)
  #  ActiveRecord::const_get(type).find(id) 
  # end
  
  # experimental stuff
 
  # Returns a sorted list of all models in this Rails application
  # For use with things like a universal ID search
  # Probably under-performant
  def list_all_models
    # preload all models
    Dir.entries("#{Rails.root}/app/models").each do |f|
      require("#{Rails.root}/app/models/" + f) if f =~ /\.rb$/
    end
  
    models = []
  
    # loop through them all in object space
    ObjectSpace.each_object { |o|
      if o.class == Class and o.superclass == ActiveRecord::Base and o.name != "CGI::Session::ActiveRecordStore::Session"
        models << o
      end
    }
  
    models.sort! {|a, b| a.name <=> b.name }
  end

  #  Returns how many times an object is used in FK relatioships (via :has_many) 
  def has_many_summary_hash(obj) # :yields: Hash (Model.to_s => String (number of records)
    obj.class.reflect_on_all_associations.select{|a| a.macro == :has_many}.inject({}){|sum, assoc|
    sum.merge!(assoc.class_name => Kernel.const_get(assoc.class_name).find(:all, :conditions => ["?  = #{obj.id}", (assoc.options[:foreign_key].blank? ? "#{obj.class.to_s.downcase}_id" : assoc.options[:foreign_key])  ] ).size ) }
  end

  # debug stuff -- for finding sources of memory leaks

  def all_strings(min = 0)
    GC.start
    counts = Hash.new(0)
    ObjectSpace.each_object { |o|
      if o.class.to_s == "String"
        counts[o] += 1
      end
    }
    foo = counts.sort {|a,b| b[1]<=>a[1]}
    bar = "<br/>"
    foo.each {|x|
      bar << "#{x[1]}: #{x[0]} <br/>\n" if x[1] > min
    }
    bar
  end

  def inspectr(class_name)
    foo = "<code>"
    ObjectSpace.each_object { |o| 
      foo << o.inspect + "<br/>\n" if o.class.to_s == class_name
    }
    foo + "</code>"
  end

  def obj_hash(min = 0)
    GC.start
    counts = Hash.new(0)
    ObjectSpace.each_object { |o| counts[o.class] += 1 }
    foo = counts.sort {|a,b| b[1]<=>a[1]}
    bar = "<br/>"
    foo.each {|x|
      bar << "#{x[1]}: #{x[0]} <br />\n" if x[1] > min
    }
    bar
  end
  
end

