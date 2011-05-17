# == Schema Information
# Schema version: 20090930163041
#
# Table name: content_templates
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)     not null
#  is_default :boolean(1)      not null
#  is_public  :boolean(1)      not null
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

class ContentTemplate < ActiveRecord::Base
  has_standard_fields

  # has_and_belongs_to_many :content_types
  has_many :content_types, :through => :content_templates_content_types, :order => 'content_templates_content_types.position'
  has_many :content_templates_content_types, :order => 'position', :dependent => :destroy
  has_many :public_content_types, :through => :content_templates_content_types, :source => 'content_type', :conditions => 'content_types.is_public = true', :order => 'position'
  has_many :mx_content_types, :through => :content_templates_content_types, :source => 'content_type', :conditions => 'content_types.sti_type != "ContentType::TextContent"', :order => 'position'
  has_many :text_content_types, :through => :content_templates_content_types, :source => 'content_type', :conditions => 'content_types.sti_type = "ContentType::TextContent"', :order => 'position'

  validates_uniqueness_of :name, :scope => 'proj_id'
  validates_presence_of :name

  def content_by_otu(otu, in_public = false) # :yields: Hash (ContentType => content) | nil
    return {} if otu.nil?

    if in_public
      contents = otu.contents.that_are_published.in_content_template(self) 
    else
      contents = otu.contents.that_are_publishable.in_content_template(self) 
    end

    content = {}

    self.mx_content_types.each do |ct|
      content.merge!(ct => true)
    end

    contents.each do |c|
      content.merge!(c.content_type => c)
    end

    content
  end

  # returns a hash with the ContentType pointing to the Content
  def text_content(otu, is_public = false)
    ts = self.text_content_types 
    # rewrite to a hash 
    otu.contents.inject({}) do |memo, o|
      ts.include?(o.content_type) && o.is_public ? memo.update({o.content_type.id => o}) : memo 
    end
  end

  def display_name(options = {})
    name
  end

  def publish(otu) # :yields: true
    return false if not otu
    p = self.public_content_types
    otu.contents.that_are_editable.each do |c|
      if p.include?(c.content_type) && c.content_type.class == ContentType::TextContent
        c.publish
      end
    end

    true
  end

  # returns ContentTypes
  def available_text_content_types # available to add
    ContentType.find(:all, :conditions => {:proj_id => self.proj_id, :sti_type => 'ContentType::TextContent'}) -  self.content_types
  end

  # returns Array of Strings
  def available_mx_content_types2 # not presently included in the template
    (ContentType::BUILT_IN_TYPES - self.mx_content_types.collect{|s| s.sti_type})  # .collect{|c| c.gsub(/ContentType::/, "")}
  end

  # returns an Array of ContentType subclasses
  def available_mx_content_types # not presently included in the template
    (ContentType::BUILT_IN_TYPES - self.mx_content_types.collect{|s| s.sti_type}).collect{|ct| ct.constantize}  # .collect{|c| c.gsub(/ContentType::/, "")}
  end

  def add_or_remove_content_type(params)
    if params[:out]
      if ct_out = ContentTemplatesContentType.find(:first, :conditions => ["content_template_id = ? AND content_type_id = ?",  self.id, params[:content_type_id]])
        self.content_templates_content_types.delete(ct_out)
      else
        return false
      end
    else
      begin
        c = ContentTemplatesContentType.new(:content_template => self)
        if params[:content_type_id]
          ctype = ContentType.find(params[:content_type_id])
        elsif params[:mx_content_type]
          ctype = ContentType.create_if_needed(params[:mx_content_type], self.proj_id)
        else
          raise
        end
        c.content_type_id = ctype.id
        c.save!
      rescue Exception => e
        return false
      end
    end
    true
  end

  # Called from OtuController#_update_content_page
  # TODO: Error rescues
  def update_content(params) # :yields: True 
    # params is a merge of form params, :otu, and (existing) :contents     
    return false if params[:otu].class != Otu

    for type in self.text_content_types
   
     # get the form content 
      con_h = {
        "text" =>          params[:content]["#{type.id}"][:text].strip,
        "is_public" =>    (params[:content]["#{type.id}"][:is_public].nil? ? 0 : 1),
        'is_image_box' => (params[:content]["#{type.id}"][:is_image_box].nil? ? 0 : 1) 
      }
     
      if con = params[:contents].detect {|c| c.content_type_id == type.id} # update or delete  
        if (con_h["text"].andand.strip.length == 0 ) && (con_h['is_image_box'] == 0) 
          con.destroy
        else
          if (con_h['is_image_box'] == 1)
            con_h['text'] = '-- image box --' 
          end 
          con.update_attributes(con_h)
        end
         
      else                      # insert or no action
     
        con_h[:content_type_id] = type.id  
        con_h[:is_public] = true
      
        if (con_h['is_image_box'] == 1)   # insert
          con_h[:is_image_box] = true
          con_h[:text] = '-- image box --'
          params[:otu].contents.create(con_h)
        elsif (con_h[:text].andand.length != 0)   # insert
          con_h[:content_type_id] = type.id 
          con_h[:is_image_box] = false
          params[:otu].contents.create(con_h)
        end
      end
    end # end content_type loop
    
    true
  end

  def transfer_to_otu(otu_in, otu_out, delete_from_incoming = true)
    self.text_content_types.each do |ct|
      if c = Content.find(:first, :conditions => {:otu_id => otu_in.id, :content_type_id => ct.id})
        c.transfer_to_otu(otu_out, false)
      end
    end
  end

  # TODO: develop
  def taxon_treatment(options = {})
    opt = { :target => ''}.merge!(options)

    doc = Builder::XmlMarkup.new(:indent => 2, :target => opt[:target])
    doc.instruct!(:xml, :version => "1.0", :encoding => "ISO-8859-1")

    doc.body do |body|
      self.content_types.each do |ct|
        ct.tp_xml(:target => opt[:target])
      end
    end
    return opt[:target]
  end

  # returns a ContentTemplate instance or nil based on passed options 
  def self.template_to_use(template_id = nil, proj_id = nil)
    return nil if template_id.nil? && proj_id.nil?
    if template_id.nil?
      # change to use project side setting
      @content_template = Proj.find(proj_id).default_content_template
      # try and use one if we can't find a default
      @content_template = ContentTemplate.find(:first, :conditions => {:proj_id => proj_id}) if !@content_template
    else
      @content_template = ContentTemplate.find(template_id)
    end
    return @content_template 
  end

end
