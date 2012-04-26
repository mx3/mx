# == Schema Information
# Schema version: 20090930163041
#
# Table name: refs
#
#  id             :integer(4)      not null, primary key
#  namespace_id   :integer(4)
#  external_id    :integer(4)
#  serial_id      :integer(4)
#  valid_ref_id   :integer(4)
#  language_id    :integer(4)
#  pdf_id         :integer(4)
#  year           :integer(2)
#  year_letter    :string(255)
#  ref_type       :string(50)
#  title          :text
#  volume         :string(255)
#  issue          :string(255)
#  pages          :string(255)
#  pg_start       :string(8)
#  pg_end         :string(8)
#  book_title     :text
#  city           :string(255)
#  publisher      :string(255)
#  institution    :string(255)
#  date           :string(255)
#  language_OLD   :string(255)
#  notes          :text
#  ISBN           :string(14)     # DEPRECATED
#  DOI            :string(255)    # DEPRECATED
#  is_public      :boolean(1)
#  pub_med_url    :text           # DEPRECATED
#  other_url      :text           # DEPRECATED
#  full_citation  :text
#  temp_citation  :text
#  display_name   :string(2047) --- now cached_display_name
#  short_citation :string(255)
#  author         :string(255)
#  journal        :string(255)
#  creator_id     :integer(4)      not null
#  updator_id     :integer(4)      not null
#  updated_on     :timestamp       not null
#  created_on     :timestamp       not null
#

class Ref < ActiveRecord::Base	
  require 'reph'
  has_standard_fields
  
  include ModelExtensions::Taggable
  include ModelExtensions::Identifiable
  include ModelExtensions::DefaultNamedScopes

  before_save :update_short_citation
  after_update :save_authors 

  # WARNING: if adding new associations you may have to update the replace_with
  # method below!

  belongs_to :language
  belongs_to :pdf, :dependent => :destroy
  belongs_to :serial
  belongs_to :valid_ref, :foreign_key => :valid_ref_id, :class_name => 'Ref'
  belongs_to :namespace

  # has_manys that are only :nullify
  has_many :association_supports, :dependent => :nullify
  has_many :chrs, :foreign_key => "cited_in", :dependent => :nullify
  has_many :claves, :class_name => 'Clave', :dependent => :nullify
  has_many :codings, :foreign_key => "ref_id", :dependent => :nullify
  has_many :images, :dependent => :nullify
  has_many :otus, :foreign_key => "source_ref_id", :dependent => :nullify
  has_many :primers, :dependent => :nullify
  has_many :seqs, :dependent => :nullify
  has_many :sensus, :dependent => :nullify
  has_many :ontology_classes, :through => :sensus
  has_many :taxon_names, :dependent => :nullify
  has_many :taxon_hists, :dependent => :nullify

  has_many :ontology_classes, :foreign_key => :written_by_ref_id # don't nullify or delete, throw an error

  # has_manys that are :destroy
  has_many :authors, :dependent => :destroy, :order => 'position' # both authors and editors
  has_many :auths, :class_name => 'Author', :conditions => {:auth_is => 'author'}, :order => 'position' # only authors (hmm- not available to @ref.auths when creating new!)
  has_many :distributions, :dependent => :destroy
  has_many :editors, :class_name => 'Author', :conditions => 'auth_is = "editor"', :order => 'position' # only editors
  has_many :labels_refs, :order => 'total DESC, labels.name ASC', :include => :label, :dependent => :destroy # a count, strictly utility now
  has_many :projs_refs, :dependent => :destroy
  has_many :projs, :through => :projs_refs
  has_many :through_tags, :class_name => 'Tag', :foreign_key => "ref_id", :dependent => :destroy # tags using a given reference
  
  # careful, these scopes are not Project specific, typically you should use them like @proj.refs.with_author_last_name('Foo')
  scope :with_author_last_name, lambda {|*args| {:order => 'refs.year', :include => :authors, :conditions => ["authors.last_name = ?", (args.first || -1)] }}
  scope :with_last_name_first_letter, lambda {|*args| {:include => :authors, :conditions => ["authors.last_name LIKE ?", ("#{args.first}%" || -1)] }}
  scope :with_pdfs, :conditions => 'pdf_id is not null' 
  scope :used_in_sensus, :include => :sensus, :conditions => "refs.id IN (SELECT ref_id FROM sensus)"
  scope :used_in_ontology_class_written_by, :include => :ontology_classes, :conditions => "refs.id IN (SELECT written_by_ref_id FROM ontology_classes)"
  scope :from_proj, lambda { |*args| {:conditions => ["refs.id IN (SELECT ref_id from projs_refs where projs_refs.proj_id = ?)", (args.first ||= 1)]} } # NOT the same as in ModelExtensions::DefaultNamedScopes
  scope :with_ocr_text_containing, lambda { |*args| {:conditions => ["refs.ocr_text like ?", args.first ? "%#{args.first}%" : -1]} }
  scope :without_serials, :conditions => 'refs.serial_id is null'

  # validates_format_of :xref, :with => /\A\w+\:\w+\Z/i, :message => 'must be in the format "foo:bar"', :if => Proc.new{|o| !o.xref.blank?} 
  validates_associated :authors

  validate :check_record
  def check_record
    if pg_start.blank? && !pg_end.blank?
      errors.add(:pg_end, "Provide a page start if you give a page end, or provide a page start alone.")
    end
  end

  # Adds Ref#total as well
  def self.by_author_first_letter_and_proj_id(letter = "a", proj_id = nil)
    Ref.find_by_sql(["SELECT COUNT(refs.id) AS total, authors.last_name
               FROM refs LEFT JOIN authors ON refs.id = authors.ref_id
               LEFT JOIN projs_refs ON refs.id = projs_refs.ref_id
               LEFT JOIN projs ON projs.id = projs_refs.proj_id
               WHERE authors.last_name LIKE ? AND projs.id = ? 
               GROUP BY authors.last_name ORDER BY authors.last_name", "#{letter}%", proj_id])   
  end

  def save_authors
    authors.each do |a|
      a.save(:validate => false) # passing false ignores validation
    end
    # true 
  end

  # railscasts thnx
  def author_attributes=(author_attributes)
    author_attributes.each do |attributes|
      if attributes[:id].blank?
        authors.build(attributes)
      else
        a = authors.detect { |t| t.id == attributes[:id].to_i } # Ref#author is a method too
        a.attributes = attributes
      end
    end
    self.update_cached_display_name # maybe a better place for this?!
  end

  def display_name(options = {})
    @opt = {
      :type => :cached # :new_record
    }.merge!(options.symbolize_keys)

    s = ''

    case @opt[:type]
    when :authors_year 
      s = authors_for_display	
      s = editors_for_display if s == '<i>no authors given</i>'
      s += '.' unless s =~ /\.$/      
      s += " #{self.year}" if !self.year.blank?
      # TODO: make inclusion of author_year letter a property of a project parameter ... this is terrible right now
      s += "#{year_letter}" if (!year_letter.blank? && projs.map(&:id).include?(16))
      s += "."
    when :selected
      self.cached_display_name
    when :new_record
      render_full_citation
    when :xref # TODO: identifiers xrefs
      return self.xref if !self.xref.blank?
      return self.cached_display_name if !self.authors_year.empty?
      "" 
    else 
      self.cached_display_name
    end 
  end

  ## returns an Array of Strings of all other possible xrefs for this reference
  #def alternate_xrefs
  #  xrefs = []
  #  xrefs << "DOI:#{self.DOI}" unless self.DOI.blank?
  #  xrefs << "ISBN:#{self.ISBN}" unless self.ISBN.blank?
  #  xrefs << "#{self.other_url}" unless self.other_url.blank?
  #  xrefs
  #end

  def in_proj?(proj)
    return true if ProjsRef.find_by_proj_id_and_ref_id(proj.id, self.id)
    false
  end

  def can_edit?(person_id)
    sql = Person.find(person_id).projs.collect{|p| "proj_id = #{p.id}"}.join(" OR ")
    return true if ProjsRef.find_by_ref_id(self.id, :conditions => sql)
    false
  end

  ## Merging and cross project code ##
  
  # Replaces all foreign keys to this Ref or sets them to 
  # null, but only within the current project, then deletes
  # the ref if there are no links to it.
  # Accepts a ref object or just an id
  def delete_or_replace_with(new_ref = nil) 
    self.class.transaction do
      new_ref = self.class.find(new_ref) unless new_ref.is_a?(self.class) || new_ref == nil
      return if new_ref == self
      
      excludes = [:authors, :auths, :editors, :projs_refs, :labels_refs, :keywords,:parts_refs] # added :projs_refs and :labels_refs here Nov/09
      assocs = self.class.reflect_on_all_associations.reject{|a| excludes.include?(a.name) }
      people_to_notify = []
      
      assocs.select{|a| a.macro == :has_many }.each do |assoc|
        klass = Kernel.const_get(assoc.class_name)
        if klass.column_names.include?('proj_id') # objects belonging to this project
          conditions = ["#{assoc.primary_key_name} = ? AND proj_id = ?", self.id, $proj_id]
          # deal with :as => :somethingable associations, like tags
          if assoc.options[:as]
            conditions[0] += " AND #{assoc.options[:as]}_type = ?"  # huh? why arrayed?
            conditions << self.class.name
          end
          if assoc.options[:dependent] == :destroy && !new_ref
            klass.find(:all, :conditions => conditions).each { |o| o.destroy }
          else
            klass.update_all("#{assoc.primary_key_name} = #{new_ref ? new_ref.id : 'NULL'}", conditions)
          end
        else # objects shared with other projects
          
          # if it is a TaxonName or TaxonHist (the only ones in this category currently)
          # we can update it if this user has permissions, otherwise we just skip it.
          if klass == TaxonName || klass == TaxonHist
            self.send(assoc.name.to_sym).each do |rec|              
              klass == TaxonHist ? tn = rec.taxon_name : tn = rec
              if tn.in_ranges?(Person.find($person_id).editable_taxon_ranges)
                rec.update_attribute(assoc.primary_key_name, (new_ref ? new_ref.id : nil))
              else
                people_to_notify << rec.creator_id
              end
            end
          end
          
        end
      end
      
      people_to_notify.uniq.map do |id|
        RefMailer.taxon_name_notice(new_ref, self, Person.find(id)).deliver
      end  
      
      # # if we add more habtm relationships, code like this may be what we want
      # assocs.select{|a| a.macro == :has_and_belongs_to_many }.each do |assoc|
      #   current_objs = new_ref.send(assoc.name.to_sym)
      #   new_objs = self.send(assoc.name.to_sym)
      #   new_ref.send("#{assoc.name}=".to_sym, (current_obj + new_objs).uniq )
      #   self.send("#{assoc.name}=", [])
      # end
      
      # update the links in text fields
      regex = Regexp.new("<ref\s+id=\"#{self.id}\">")
      Content.find(:all, :conditions => ["text LIKE '%id=\"#{self.id}\"%' AND proj_id = ?", $proj_id]).each do |c|
        c.update_attribute('text',  c.text.gsub(regex){|m| "<ref id=\"#{new_ref ? new_ref.id : nil}\">"})
      end
      
      self.update_attribute('valid_ref_id', new_ref.id) if new_ref
      Proj.find($proj_id).refs.delete(self) # remove it from the projs_refs association
      
      # now test to see if the ref is used anywhere, and delete if not
      linked = false
      assocs.select{|a| [:has_many, :has_and_belongs_to_many, :has_one].include?(a.macro) }.each do |assoc|
        linked = true unless self.send(assoc.name.to_sym, true).empty? # need to pass true to force update
        # puts "linked to #{assoc.name}.#{assoc.primary_key_name}" unless self.send(assoc.name.to_sym).empty?
      end
      self.destroy unless linked
    end
  end
  
  def notify_if_needed(old_ref, old_authors)
    # create a diff as {field_name => [old, new]}
    diff_hash = {}
    auth_ar = [old_authors, self.authors].map do |the_auths|
      the_auths.map {|a| "#{a.last_name}, #{a.first_name}, #{a.initials} (#{a.auth_is})"}.join("; ")
    end
    diff_hash["authors"] = auth_ar unless auth_ar[0] == auth_ar[1]
    
    excludes = %w(id cached_display_name short_citation creator_id updator_id created_on updated_on)
    attrs = self.attributes.reject{|k, v| excludes.include?(k) }
    # collect the attributes that have changed (excluding changes like nil -> "")
    attrs.each_pair do |k,v|
      diff_hash[k] = [old_ref[k], v] if old_ref[k] != v && !(v.blank? && old_ref[k].blank?)
    end
    self.logger.info diff_hash.to_yaml
    
    return if diff_hash.empty? # no mail if no changes
    
    # send to: all members of (all projects using this ref - current project) - current user
    projs = Proj.find(:all, :include => [:refs, :people], :conditions => ["refs.id = ? AND projs.id != ?", self.id, $proj_id])
    # use a hash to flatten the people and record who goes with which proj
    h = {}
    projs.each do |proj| 
      proj.people.pref_receive_reference_update_emails.each{|person| h[person] = proj}
    end
    h.delete_if{|p| p.id == $person_id} # don't send to current user
        
    # no mail if no other projects
    h.each_pair {|person, person_proj| RefMailer.update_notice(self, diff_hash, person, person_proj).deliver }
  end

  # this gets called on update through has_standard_fields
  def update_cached_display_name
    if !self.title.blank? && !self.year.blank? && !(self.authors.size == 0) # then render from parts
      s = render_full_citation
    elsif !full_citation.blank?
      s = full_citation
    else 
      s = temp_citation
    end

    s = 'Reference incomplete.' if s.blank?
	  self.cached_display_name = s 
    true
  end

  # DEPRECATED FOR IDENTIFIERS
  # def DOI_url(link_txt = 'resolve DOI')
  #   if self.DOI.blank?
  #     ''
  #   else
  #     '<a href="http://dx.doi.org/' + self.DOI + '" target="_blank">' + link_txt + '</a>'
  #   end
  # end
	
  ## Rendering ##

  def self.valid_reference_types # references types primarily define (ultimately) how refs are rendered for display
    ['Journal Article', 'Book', 'Report', 'Thesis', 'Book Section', 'Conference Proceedings', 'Map', 'Manuscript', 'Electronic Source', 'Dissertation', 'Xref']
  end

  def authors_for_display 
    as = self.authors.reject{|a| a.auth_is != "author"}
    return '' if !as
    case as.size
    when 0
      author.blank? ? "<i>no authors given</i>" : author # DEPRECATED
    when 1
      as.first.display_name
    when 2 # could likely be merged with below
      as.first.display_name + ", and " + as.last.display_name_initials_first
    else
      as.first.display_name + ", " + as[1..(as.size - 2)].collect{|o| o.display_name_initials_first}.join(", ") + ", and " +  as.last.display_name_initials_first
    end 
  end

  
  def editors_for_display 
    # see authors_for_display for this hack
    eds =[] 
    if self.new_record?
      eds =  self.authors.inject([]) {|sum, o| sum.push(o.auth_is == "editor" ? o : nil)}.compact
    else
      eds = self.editors
    end
    
    if eds.empty?
      return ''
    else
      return eds.collect{|o| o.display_name}.join(", ") + " (eds.)"
    end	
  end
  
  # returns authors formatted for use in taxon names, works for 1-many authors only!!!
  def authors_for_taxon_name
    s = ''
    as = self.auths
    
    if as.empty? # check if the old (DEPRECATED) author field is being used
      s += author if author
      s += (', ' + year.to_s) if year
      return s if s.size > 0      
      return nil # don't change
    else
      
      case as.size
      when 0
        # do nothing
      when 1
        s =  as.first.last_name
      when 2 # could likely be merged with below
        s = as.first.last_name + " and " + as[1].last_name # weird, as.last broken in Rails 2.1
      else
        s = as[0..(as.size - 1)].collect{|o| o.last_name}.join(", ") + ", and " +  as.last.last_name
      end 
      s += ", #{year}" if year
    end
    s
  end

  ## ---- Rendering a Reference ---- ##
  
  # Now follows Systematic Biology by default
 
  # TODO: deprecate to display_name(:type => :authors_year) 
  def authors_year
    s = ''
    s = authors_for_display
    s = editors_for_display if s == '<i>no authors given</i>'
    s += '.' unless s =~ /\.$/
    s += " #{self.year}" if !self.year.blank?
    # TODO: make inclusion of author_year letter a property of a project parameter ... this is terrible right now
    s += "#{year_letter}" if ( !year_letter.blank? && projs.map(&:id).include?(16))
    s += "."
  end
  
  def authors_year_title
    s = ''
    s = authors_year
    s += (" #{title.gsub(/\./, '')}.") if title? # no punctuation in title (hmm- likely not safe assumption)
    return s
  end
 
  def render_full_citation # renders a display_name from parts 
    case ref_type
    when 'foo'
      return 'curious, your ref is a foo'
        
    when 'Xref'
      return "TODO: self.title"

    when 'Book Section'
      s = authors_year_title
      if not pg_start.blank?
        if !pg_start.blank? && !pg_end.blank?
          s << " Pp. #{pg_start}-#{pg_end}"
        else
          s << " P. #{pg_start}" # you can no longer have page end by itself
        end
      end
        
      s << " in: #{book_title}. " unless book_title.blank?
      s << editors_for_display + " "
      s << [publisher, city].reject(&:blank?).join(",")
      s << ". #{pages} pp" if pages
        
    when 'Thesis'
      s = authors_year_title
      s <<  " #{institution}, #{city}, #{pages} pp"
        
    when 'Book'
      s = authors_year_title
      s << " #{publisher}" unless publisher.blank?
      s << ", " unless publisher.blank? and not city.blank?
      s << "#{city}" unless city.blank?
      s << "." unless city.blank? or not publisher.blank?
      s << " #{pages} pp" unless pages.blank?
      # when "Conference Proceedings"
        
    else # nothing special - render as serial/journal article
      s = authors_year_title
      if serial_id?
        s << " " + serial.name
      elsif journal
        s << " " + journal
      end
      s << " #{volume}" if volume?
      # s << ("(" + issue.gsub(/([\(\)\s])/, '') + ")") if issue? # () and whitespace should not be included in issue
      if pg_start?
        s << (pg_end? ? ":#{pg_start}-#{pg_end}" : (":#{pg_start}"))
      else
        s <<  ":#{pages}" if pages?
      end
    end
    return s + '.'
  end

  def url_for_display
    s = ''
    pub_med_url? ? s << "<a href=\"#{pub_med_url}\">pub-med</a>" : ''  # 
    other_url? ? s << " " + "<a href=\"#{other_url}\">other</a>" : ''  #  
  end
  
  def update_short_citation
    # see authors_year for comments on the new_record bit
    if self.new_record?
      as = authors.inject([]) {|sum, o| ( o.auth_is == "author") && sum.push(o)}
    else
      as = self.auths
    end
    
    if as # still get hits when editors are there
      s = case as.size
      when 0..2
        as.collect{|a| a.last_name}.join(" &amp; ")
      else
        as[0].last_name + " et al."
      end
    else
      s = 'unknown'
    end 
      
    self.short_citation = "#{s} #{year}"
  end

  def text_citation
    s = case auths.size
    when 0
      '(No authors given)'
    when 1
      (auths.first.last_name? ? auths.first.last_name : 'NO LAST NAME')  + " (#{year})"
    when 2
      auths.collect{|a| a.last_name? ? a.last_name : 'NO LAST NAME' }.join(" and ") +  " (#{year})"
    else
      (auths[0].last_name? ? auths[0].last_name : 'NO LAST NAME') + " et al. (#{year})"
    end
  end

  def self.new_from_endnote (options = {})
    opt = {
      :proj_id => nil,
      :save => false,
      :endtext => nil
    }.merge!(options)

    raise Ref::RefBatchParseError, "Provide something to parse."  if opt[:endtext].blank?
    raise Ref::RefBatchParseError, "No project specified."  if opt[:proj_id].blank?

    serials = []                                                         # a working list of new Serials
    @results = Rephs::Rephs.new()                                        # a utility object, see /lib/rephs 
    result = RubyEndnote::parse_refs(:txt => opt[:endtext])    

    # new objects
    result.each do |r|
      # deal with Serials 
      if r.type == "Journal Article" 
        if s = Serial.find(:first, :conditions => ["name = ?", r.journal_title]) # it exists
          serials.push(s) if !serials.include?(s)                                # add it to the master list
        else 
          if !serials.collect{|s| s.name}.include?(r.journal_title)              # it doesn't exist, and isn't in the list
            s = Serial.new(:name => r.journal_title) 
            serials << s
          else                                                                   # it doesn't exist and IS in the list
            s = serials.detect{|a| a.name == r.journal_title}                    # detect maybe not the right method
          end
        end
      end
   
      ref_title = r.article_title.gsub(/\W\Z/, "")  # strip trailing punctuation
   
      if ref = Ref.find(:first, :conditions => ["title = ?", ref_title]) 
        
      else
        ref = Ref.new
        ref.ref_type = r.type                        # must be Journal, Book or Book Section
        ref.title = ref_title
        ref.year = r.year
        ref.volume = r.volume
        ref.issue = r.number
        # ref.pages = r.pages # could split things here?
        ref.pg_start = r.pg_start
        ref.pg_end = r.pg_end

        ref.book_title = r.book_title
        ref.city = r.publisher_location
        ref.publisher = r.publisher
       
        # TODO: add as identifier 
        # ref.ISBN = r.isbn       
        
        ref.journal = r.journal_title # ummm is this right?
        ref.serial = s if s

        as = r.authors.join(" ,")
        as = nil if as == ""
        es = r.editor.join(" ,")
        if es == ""
          es = nil
        else
          es += " (Eds.)"
        end

        ref.author = [as, es].flatten.compact.join(" ;") # kludge, we don't use this in mx

        auths = []
        r.authors.each_with_index do |auth, i|
          temp = auth.split(",", 2)
          auths << Author.new(:auth_is => "author" ,:last_name =>temp.first.strip, :initials => temp.last.gsub(/[^A-Za-z]*/, '').upcase, :position => i)
        end
     
        eds = [] 
        r.editor.each_with_index do |edit, i|
          temp = edit.split(",", 2)
          eds <<  Author.new(:auth_is => "editor" ,:last_name =>temp.first.strip, :initials => temp.last.gsub(/[^A-Za-z]*/, '').upcase, :position => i)
        end

      end

      # store our mapping 
      t = Rephs::Reph.new(r, ref)
      t.ref_authors = auths
      t.ref_editors = eds
      @results.rephs << t
    end # end parsing loop

    if opt[:save]
      @proj = Proj.find(opt[:proj_id])
      begin
        Ref.transaction do 
          # save the Serials 
          @results.unmatched_serials do |s|
            s.save!
          end
         
          # save the Refs 
          @results.unmatched_rephs.each do |reph|
            reph.ref.save!
            reph.ref_authors.map{|a| reph.ref.authors << a}
            reph.ref_editors.map{|e| reph.ref.authors << e}
            reph.ref.save!

            reph.saved = true 
            @proj.refs << reph.ref
          end

        end

      rescue ActiveRecord::RecordInvalid => e
        raise "Error during saving a record (#{e})."
      end 
    end   

    return @results
  end 
  
  def count_labels(proj_id)
    labels_refs.destroy_all
    if !ocr_text.blank?
      @l = Linker.new(:incoming_text => self.ocr_text, :exclude_common_words => true, :proj_id => proj_id, :adjacent_words_to_fuse => 5)
      grand_total = 0
      @l.link_set(:proj_id => proj_id).each do |l|
        # total = ocr_text.scan(/\b#{l.name}\b/).size.to_i
        total = l.all_forms.inject(0){|sum, pf| sum += ocr_text.scan(/\b#{pf}\b/).size.to_i}
        grand_total += total
        LabelsRef.create!(:ref => self, :label => l, :total => total)
      end
      print " #{grand_total} matches\n"
    end
  end 

  def self.count_all_labels(proj_id)
    puts "counting"
    Ref.transaction do 
      begin
        Ref.find(:all, :conditions => "length(ocr_text) > 0").each do |r|
          print "#{r.id.to_s} ... "
          r.count_labels(proj_id)
        end
      rescue
        return false
      end
      true
    end
  end

  class RefBatchParseError < ApplicationController::BatchParseError
  end

end 

