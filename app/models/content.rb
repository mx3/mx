# == Schema Information
# Schema version: 20090930163041
#
# Table name: contents
#
#  id              :integer(4)      not null, primary key
#  otu_id          :integer(4)
#  content_type_id :integer(4)
#  text            :text
#  is_public       :boolean(1)      default(TRUE), not null
#  pub_content_id  :integer(4)
#  revision        :integer(4)
#  proj_id         :integer(4)      not null
#  creator_id      :integer(4)      not null
#  updator_id      :integer(4)      not null
#  updated_on      :timestamp       not null
#  created_on      :timestamp       not null
#

class Content < ActiveRecord::Base

  # IMPORTANT
  # pub_content_id is not null in PUBLISHED (PubContent) content, it contains the original (working) content#id
  # revision is null in Content, populated starting at 1 in PubContent

  has_standard_fields

  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  belongs_to :content_type
  belongs_to :otu

  has_one :public_version, :class_name => 'PublicContent', :foreign_key => 'pub_content_id', :dependent => :destroy

  # is_image_box contents ARE "editable"
  scope :that_are_editable, where(:pub_content_id => nil)
  scope :that_are_publishable, where("pub_content_id IS NULL AND contents.is_public = 1")
  scope :that_are_published, where("contents.pub_content_id IS NOT NULL")

  scope :by_otu, lambda {|*args| {:conditions => ["contents.otu_id = ?", args.first || -1] }}
  scope :by_content_type, lambda {|*args| {:conditions => ["contents.content_type_id = ?", args.first || -1], :include => [:content_type, :figures] }}

  scope :by_eol_legal_content_type, :include => [:content_type, :figures], :conditions => 'content_types.subject IS NOT NULL AND length(content_types.subject) != 0'

  scope :in_content_template, lambda {|*args| {:conditions => ["contents.content_type_id IN (SELECT content_type_id FROM content_templates_content_types WHERE content_templates_content_types.content_template_id = ?)", args.first || -1], :include => [:content_type] }}
  # scope :ordered_by_content_template, :include 

  validates_presence_of :text, :otu_id, :content_type_id # added otu_id, content_type_id

  # TODO: otu_id/content_type is cloned to public_content now
  # doesn't require :otu and :content_type because of public_content, should perhaps be subclassed

  # TODO: R3
  validate :validate_record
  def validate_record
    errors.add(:otu, 'content must be attached to a OTU') if !otu && pub_content_id.blank?
    errors.add(:content_type_id, 'content must be have a content type') if !content_type && pub_content_id.blank?
  end

  def display_name(options = {}) # :yields: String
    opt = {:type => nil
    }.merge!(options.symbolize_keys)
    case opt[:type]
    when :figure
      'this content' 
    else 
     self.text.slice(0..300) + (self.text.size > 300 ? "..." : '')
    end
  end
  
  def is_published # :yields: True | False
    self.public_version ? true : false
  end

  def publish # :yields: True | False
  
    begin
      Content.transaction do
        if p = self.public_version

         # if content is no longer public nuke the public version and return
         if self.is_public == false   
           p.figures.destroy_all
           p.destroy
           return true 
         end

          # check to see if text/image_box status
          if !(self.text == p.text) || !(self.is_image_box == p.is_image_box) 
            p.update_attributes(:revision => p.revision + 1, :text => self.text, :is_image_box => self.is_image_box, :pub_content_id => self.id, :otu_id => self.otu_id, :content_type_id => self.content_type_id)    
          end
     
          # wipe the public figures
          p.figures.destroy_all

          # TODO add tags handling here

        else
          p = PublicContent.new
          p.text = self.text
          p.pub_content_id = self.id # published content has pub_content_id NOT null and set to the id of the working Content
          p.content_type_id = self.content_type_id
          p.otu_id = self.otu_id
          p.is_image_box = self.is_image_box 
          p.revision = 1
          p.save!
        end

        # recreate the figures
        for f in self.figures
          fnew = f.clone
          fnew.addressable_id = p.id
          fnew.save!
        end

      end

    rescue Exception => e
      return false
    end
    return true
  end

  # transfer this content to a different Otu, if delete_from_incoming = false then the content (and figures, tags) is duplicated
  def transfer_to_otu(otu, delete_from_incoming = true)
    return false if otu.id == self.otu_id
    c = Content.find(:first, :conditions => {:otu_id => otu.id, :content_type_id => self.content_type_id})
    # does the incoming otu have this content_type already
    
    begin
      Content.transaction do
        if c # content already exists for the clone-to OTU 
          c.text = c.text + " [Transfered from OTU #{self.otu_id}: #{self.text}]"  # append content
          c.save! 
          # deal with figures
          for f in self.figures
            if found = Figure.find(:first, :conditions => {:addressable_type => 'Content', :addressable_id => c.id , :image_id => f.image_id})
              # append the caption
              found.caption +=  " [Transfered from OTU #{self.otu_id}: #{f.caption}]"
              f.destroy if delete_from_incoming
            else
              if delete_from_incoming
                # transfer the figure
                f.addressable_id = c.id
                f.save!
              else
                # clone the figure
                n = f.clone
                n.addressable_id = c.id
              end
            end
          end

          # deal with tags
          for t in self.tags
            if found = Tag.find(:first, :conditions => {:addressable_type => 'Content' , :addressable_id => c.id , :keyword_id => t.keyword_id })
              # append the notes
              
              found.notes += " [Transfered from OTU #{self.otu_id}: #{t.notes}]"
              found.save!
              t.destroy if delete_from_incoming
            else
              if delete_from_incoming
                # transfer the tag
                t.addressable_id = c.id
                t.save!
              else
                #clone the tag
                n = t.clone
                n.addressable_id = c.id
                n.save!
              end
            end
          end

          self.destroy if delete_from_incoming
   
        else  #  content in transfer-to OTU doesn't exist
          if delete_from_incoming  # just update the otu_id and everything gets transferred
            self.otu_id = otu.id
            self.save!
          else # need to clone everything
            # clone the content
            nc = self.clone
            nc.otu_id = otu.id
            nc.save!

            # clone figures
            for f in self.figures
              fn = f.clone
              fn.addressable_id = nc.id
              fn.save!
             end

            # clone tags
            for t in self.tags
              tn = t.clone
              tn.addressable_id = nc.id
              tn.save!
            end
          end
        end
      end

    rescue
      returns false
    end
    true
  end
 
  def attribution_creator # :yields: String
    maker.blank? ? creator.full_name : maker
  end

  def attribution_rights_holder # :yields: String
    if copyright_holder.blank?
      if proj.default_copyright_holder.blank?
        self.creator.full_name
      else
        proj.default_copyright_holder
      end
    else
      copyright_holder
    end
  end

  def attribution_license_uri # :yields: String
    license.blank? ? CONTENT_LICENSES[proj.default_license][:uri] : CONTENT_LICENSES[license][:uri] 
  end

  def attribution_license_text
    if license.blank?
      if proj.default_license.blank?
        'none provided' 
      else
        CONTENT_LICENSES[proj.default_license][:text]
      end
    else
      CONTENT_LICENSES[license][:text] 
    end

  end

  # maker (=creator, =author), project (= project name), editor, 

end
