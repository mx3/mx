module ModelExtensions
  module Taggable
    # include Taggable in the Model

    def self.included(base)
      base.class_eval do

        # tn = self.table_name                        # like otus
        # cn = self.table_name.singularize.capitalize # like Otu

        has_many :tags, :as => :addressable, :dependent => :destroy, :include => [:keyword, :ref], :order => 'refs.cached_display_name ASC'
        has_many :public_tags, :as => :addressable, :class_name => "Tag", :include => [:keyword, :ref], :order => 'refs.cached_display_name ASC', :conditions => 'keywords.is_public = true'
        has_many :keywords, :through => :tags

        scope :include_tags, :include => :tags

        # returns the year (integer) of the "oldest" tag by Ref#year
        def oldest_tag_by_ref_year(kw)
          oldest = 9999
          self.tags.by_keyword(kw).each do |t|
            oldest = t.ref.year if !t.ref.blank? && !t.ref.year.blank? && t.ref.year.to_i < oldest
          end
          return nil if oldest == 9999

          oldest
        end

        # returns true of self it tagged with Keyword 
        def tagged_by(keyword)
          self.tags.collect { |t| t.keyword }.include?(keyword)
        end

        def self.tagged_with_keywords(options = {})
          opt = {
              :search_with_and => false,
              :invert => false, # select without
              :keywords => [],
              :proj_id => nil
          }.merge!(options.symbolize_keys)

          return [] if opt[:keywords] == [] || opt[:proj_id] == nil

          sql = "proj_id = #{opt[:proj_id]}"

          # TODO: the AND logic requries a new AND id IN for each kw
          if opt[:search_with_and]
            if opt[:invert]
              sql += " AND id NOT IN (SELECT id from parts WHERE proj_id = #{opt[:proj_id]} " + opt[:keywords].collect { |k| " AND id in (SELECT addressable_id FROM tags WHERE addressable_type = '#{cn}' and keyword_id = #{k.id})" }.join + ")"
            else
              opt[:keywords].each do |k|
                sql += " AND id IN (SELECT addressable_id FROM tags WHERE addressable_type = '#{cn}' AND keyword_id = #{k.id})"
              end
            end
          else
            sql += " AND id #{opt[:invert] ? 'NOT IN' : 'IN'} (SELECT addressable_id FROM tags WHERE addressable_type = '#{cn}' AND (" + opt[:keywords].collect { |k| "keyword_id = #{k.id}" }.join(" OR ") + "))"
          end

          cn.constantize.find(:all, :conditions => sql, :order => :name)
        end

        # returns an integer of the number of tags created
        def tag_all_children(options = {})
          opt = {
              :has_many_class => nil, # an existing has_many relationship
              # :proj_id => nil,    # shouldn't need this, it's explicit children the project
              :keyword_id => nil,
              :notes => nil,
              :pg_start => nil,
              :pg_end => nil,
              :pages => nil
          }.merge!(options)

          return false if opt[:keyword_id].blank? || opt[:has_many_class].blank?

          klass = opt[:has_many_class].to_s.capitalize.singularize
          if  Keyword.find(opt[:keyword_id])
            ActiveRecord::Base.transaction do
              i = 0
              self.send(opt[:has_many_class]).each do |o| # .from_proj(opt['proj_id'])
                                                          # don't create for already created
                if Tag.by_class(klass).by_keyword(kw).with_addressable_id(o).count == 0
                  # ugly passing of params
                  tag = Tag.new(:addressable_id => o.id,
                                :addressable_type => klass,
                                :keyword_id => opt[:keyword_id],
                                :notes => opt[:notes],
                                :pages => opt[:pages],
                                :pg_start => opt[:pg_start],
                                :pg_end => opt[:pg_end]
                  )
                  tag.save!
                  i += 1
                end
              end # next part
            end
            i
          end
        end

      end # end class_eval
    end
  end
end
