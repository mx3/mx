# == Schema Information
# Schema version: 20090930163041
#
# Table name: people
#
#  id                      :integer(4)      not null, primary key
#  last_name               :string(255)     not null
#  first_name              :string(100)     not null
#  middle_name             :string(100)
#  login                   :string(32)
#  password                :string(40)
#  is_admin                :boolean(1)      not null
#  creates_projects        :boolean(1)      not null
#  email                   :string(255)
#  updated_on              :timestamp       not null
#  created_on              :timestamp       not null
#  pref_mx_display_width   :integer(2)      default(20)
#  pref_mx_display_height  :integer(2)      default(10)
#  pref_creator_html_color :string(6)
#

require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 
class Person < ActiveRecord::Base
  
  attr_protected :is_admin # keep people from setting is_admin=true
  attr_protected :is_ontology_admin 
  attr_protected :creates_projects # and creates_projects=true
  
  belongs_to :default_repository, :class_name => 'Repository', :foreign_key => 'pref_default_repository_id'

  has_and_belongs_to_many :editable_taxon_names, :join_table => "people_taxon_names", :class_name => "TaxonName"
  has_and_belongs_to_many :projs, :order => 'projs.name' # project membership
  # has_many :projs_created, :class_name => 'Proj', :foreign_key => "creator_id" # projects created by this person

  before_create :crypt_password
  before_update :crypt_unless_empty

  scope :pref_receive_reference_update_emails, :conditions => {:pref_receive_reference_update_emails => true}

  # TODO: People have many other relationships, these should be accessed through named scope, like Proj#otus.created_by($person_id) 
  
  # DEPRECATED
  # def projects_with_parts(current_proj_id)
  #  self.projs.delete_if{|x| x.id == current_proj_id || x.ontology_classes.count == 0 } 
  # end
    
  def full_name
    first_name + " " + last_name
  end
  
  def editable_taxon_ranges
    # because the person (and their associations) get cached in the session, it is necessary to reload
    # otherwise you will hit problems if new taxon names have been added
    editable_taxon_names.reload.collect {|t| (t.l)..(t.r)}

  end
  
  #-- authentication/login stuff --#  
  def self.authenticate(login, pass)
    find(:first, :conditions => ["login = ? AND password = ?", login, Person.sha1(pass)])
  end
  
  def display_name(options = {})
    login
  end
  
  def name # required (should depreciate to be replaced with display_name)
    login
  end

  def update_preferences(opts)
    params = opts.symbolize_keys
    self.pref_mx_display_width = params[:person]['pref_mx_display_width']
    self.pref_mx_display_height = params[:person]['pref_mx_display_height']
    self.pref_creator_html_color =  params[:person]['pref_creator_html_color']
    self.default_repository = Repository.find(params[:person]['pref_default_repository_id']) if !params[:person]['pref_default_repository_id'].blank?
    self.pref_receive_reference_update_emails = params[:person]['pref_receive_reference_update_emails']
    self.save!
  end

  protected

  # the 'foo-bar' bit helps create a unique hash (i.e. not what you would get with just SHA1).
  def self.sha1(pass)
    Digest::SHA1.hexdigest("foo#{pass}bar")
  end
    
  def crypt_password
    write_attribute("password", self.class.sha1(password)) if password == @password_confirmation
  end
  
  # If the record is updated we will check if the password is empty.
  # If its empty we assume that the user didn't want to change his
  # password and just reset it to the old value.
  def crypt_unless_empty
    if self.password.empty?      
      user = Person.find(self.id)
      self.password = user.password
    else
      if self.password != Person.find(self.id).password # could already be set .. 
        write_attribute("password", Person.sha1(password)) 
      end  
    end        
  end  
  
  validates_length_of :login, :within => 4..40
  validates_length_of :password, :within => 8..40
  validates_presence_of :password, :login
  validates_presence_of :first_name, :last_name, :email, :on => :create
  validates_uniqueness_of :login, :on => :create
  validates_confirmation_of :password 
  validates_length_of :pref_creator_html_color, :is => 6, :allow_blank => true


end
