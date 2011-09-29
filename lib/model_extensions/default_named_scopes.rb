module ModelExtensions::DefaultNamedScopes 

  # This name scope set assumes that the model has
  # id, proj_id, creator_id, updator_id
  # TODO: add this logic and fail with RAISE

  def self.included(base)
      
    base.class_eval do

      # sensu Railscasts #112
      
      # HMM- > this can't be good  in rails 3
      # scope :conditions, lambda { |*args| {:conditions => args}}

      # scope :for_period, lambda { |from, to| {
      #             :conditions => ["#{self.table_name}.#{self.to_s.downcase}_date >= ? AND #{self.table_name}.#{self.to_s.downcase}_date <= ?", from, to] } }

      # column names
      # {self.columns.map(&:name).join(",")}

      tn = self.table_name                        # like otus
      cn = self.table_name.singularize.capitalize # like Otu

      scope :tagged_with_keyword, lambda {|*args| {:conditions => ["id IN (SELECT addressable_id FROM tags WHERE tags.addressable_type = '#{cn}' AND keyword_id = ?)", (args.first ? args.first : -1)]}}
      scope :tagged_with_keyword_string, lambda {|*args| { :conditions => ["#{tn}.id IN (SELECT addressable_id FROM tags WHERE addressable_type = '#{cn}' AND tags.keyword_id = (SELECT id FROM keywords WHERE keyword = ?))", args.first ? "#{args.first}" : -1] }}

      # `is_public` scopes
      if self.columns.map(&:name).include?('is_public')
        scope :is_public, :conditions => {:is_public => true}
      end

      # `confidence` scopes
      if self.columns.map(&:name).include?('confidence_id')
        scope :with_confidence, lambda {|*args| {:conditions => ["#{tn}.confidence_id = ?", args.first || -1]}}
      end

      # `name` scopes
      if self.columns.map(&:name).include?('name')
        scope :by_name, lambda {|*args| {:conditions => ["name = ?", (args.first ? "#{args.first}" : -1)]}}
        scope :ordered_by_name, :order => 'name ASC'
      end

      # `cached_display_name` scopes
      if self.columns.map(&:name).include?('cached_display_name')
        scope :ordered_by_cached_display_name, :order => "#{tn}.cached_display_name ASC"
      end

      # `position` scopes
      if self.columns.map(&:name).include?('position')
        scope :ordered_by_position, :order => "#{tn}.position ASC"
      end

      # id scopes
      scope :ordered_by_id, :order => 'id ASC'
      scope :excluding_id, lambda {|*args| {:conditions => ["#{tn}.id != ?", (args.first ? "#{args.first}" : -1)]}}
       
      # date scopes
      scope :recently_changed, lambda {|*args| {:conditions => ["(#{tn}.created_on > ?) OR (#{tn}.updated_on > ?)", (args.first || 2.weeks.ago), (args.first || 2.weeks.ago)] }}
      scope :ordered_by_updated_on, :order => 'updated_on DESC'
      scope :ordered_by_created_on, :order => 'created_on DESC'

      # person scopes
      scope :changed_by, lambda {|*args| {:conditions => ["(#{tn}.creator_id = ?) OR (#{tn}.updator_id = ?)", (args.first || -1), (args.first || -1)] }}
      scope :not_changed_by, lambda {|*args| {:conditions => ["(#{tn}.creator_id != ?) AND (#{tn}.updator_id != ?)", (args.first || -1), (args.first || -1)] }}
      scope :created_by, lambda {|*args| {:conditions => ["#{tn}.creator_id = ?",  (args.first || -1)] }}

      # project scopes
      # was :from_proj
      scope :by_proj, lambda {|*args| {:conditions => ["#{tn}.proj_id = ?", args.first || -1] }} # useful in refs case

      # SQL scopes
      # scope :limit, lambda {|*args| {:limit => (args.first.to_i || -1) }}

      # tag scopes
      # TODO:
      # scope :without_tags
      # scope :with_tags
        
    end
  end
end

# ActiveRecord::Base.send(:include, DefaultNamedScopes)
