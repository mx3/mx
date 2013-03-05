class Sensu < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes

  acts_as_list :scope => :ontology_class

  belongs_to :ref
  belongs_to :ontology_class
  belongs_to :label

  validates_presence_of :ref, :ontology_class, :label

  # TODO: moved some of these to shared scopes
  scope :by_ref, lambda {|*args| {:conditions => ['sensus.ref_id = ?', (args.first || -1)] }} 
  scope :by_label, lambda {|*args| {:conditions => ['sensus.label_id = ?', (args.first || -1)] }} 
  scope :by_ontology_class, lambda {|*args| {:conditions => ['sensus.ontology_class_id = ?', (args.first || -1)] }} 
  scope :excluding_label, lambda {|*args| {:conditions => ['sensus.label_id != ?', (args.first || -1)] }} 
  scope :excluding_ontology_class, lambda {|*args| {:conditions => ['sensus.ontology_class_id != ?', (args.first || -1)] }} 

  scope :syn, lambda {|*args| {:conditions => ["sensus.label_id in (SELECT label_id, count(s.ontology_class_id) c from sensus s group_by(s.ontology_class_id) where s.ontology_class_id = ?)", (args.first | -1)] }}  

  scope :ordered_by_label, :order => 'labels.name', :include => :label 
  scope :ordered_by_age, :order => 'refs.year', :include => [:label, :ref]

  scope :including_label, :include => :label

  validates_uniqueness_of :label_id, :scope => [:ref_id, :ontology_class_id, :proj_id], :message => "That sensu already exists in this project."

  after_create :energize_create_sensu
  after_destroy :energize_destroy_sensu

  def energize_create_sensu
    self.ontology_class.labels.each do |l| 
      l.energize(creator_id, "created a sensu for the label")
      l.save!
    end 
    true
  end

  def energize_destroy_sensu(person_id = $person_id)
    self.ontology_class.labels.each do |l| 
      l.energize(person_id, "destroyed a sensu for the label")
      l.save!
    end 
    true
  end

  def display_name(options = {})
    opt = {
      :type => :line, #:selected
      :target => ""
      }.merge!(options.symbolize_keys)

      xml = ::Builder::XmlMarkup.new(:indent=> 2, :target => opt[:target])

      case opt[:type]
      when :selected
        xml << "#{self.label.name} / #{self.ontology_class.definition} / #{self.ref.authors_year}"  
      else
        # TODO: is this right?
        xml.div('', "style" => 'border-bottom: 1px solid silver;' )
        xml.strong(self.label.name)
        xml << " / "
        xml << self.ref.authors_year
        xml.div('', 'style' => 'border-bottom: 1px solid silver;')
        xml.div(self.ontology_class.definition, 'style' => 'color:#888; padding: 2px; margin-bottom: 2px; font-size: smaller;')
      end 
      opt[:target] 
    end

    # returns an Array of Arrays of Parts, Parts represent labels for self.ontology_class
    def acts_of_synonymy_for_ref
      syn = self.proj.sensus.by_ontology_class(self.ontology_class_id).by_ref(self.ref_id).ordered_by_label.collect{|s| s.label}.uniq
      syns = []
      syn.each_with_index do |s1,i|
        syn[(i+1)..(syn.size)].each do |s2|
          syns << [s1, s2]
        end
      end
      syns
    end

    # returns an Array of Arrays of OntologyClasses
    def acts_of_homonymy_for_ref
      syn = self.proj.sensus.by_label(self.label_id).by_ref(self.ref_id).ordered_by_label.collect{|s| s.ontology_class}.uniq
      syns = []
      syn.each_with_index do |s1,i|
        syn[(i+1)..(syn.size)].each do |s2|
          syns << [s1, s2]
        end
      end
      syns
    end

    def self.auto_complete_search_result(params = {})
      tag_id_str = params[:tag_id]
  
          value = params[tag_id_str.to_sym].split.join('%') # hmm... perhaps should make this order-independent

          lim = case params[tag_id_str.to_sym].length
            when 1..2 then  10
            when 3..4 then  25
            else lim = false # no limits
          end 

         Sensu.find(:all, :conditions => ["(labels.name like ? OR ontology_classes.definition like ? OR refs.cached_display_name like ? OR sensus.id = ?) AND sensus.proj_id=?", "%#{value}%", "%#{value}%", "%#{value}%", value.gsub(/\%/, ""), params[:proj_id]], :order => "labels.name, sensus.id", :limit => lim, :include => [:label, :ontology_class, :ref] )
      end

  end
