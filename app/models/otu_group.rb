# == Schema Information
# Schema version: 20090930163041
#
# Table name: otu_groups
#
#  id         :integer(4)      not null, primary key
#  name       :string(64)
#  is_public  :boolean(1)
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

class OtuGroup < ActiveRecord::Base
  has_standard_fields

  has_many :otu_groups_otus, :order => 'position', :dependent => :destroy
  has_many :otus, :through => :otu_groups_otus, :order => 'otu_groups_otus.position'
  has_many :lots, :finder_sql => proc { "Select l.* from lots l join otus o on l.otu_id = o.id join otu_groups_otus ogo on ogo.otu_id = #{id};"}, :class_name => 'Lot'

  has_and_belongs_to_many :mxes

  validates_presence_of :name

  before_destroy :update_matrices
  # you MUST add Otus with the add_otu(Otu) method, NOT << !!
  # similary remove them with remove_otu(Otu), not .delete

  def add_otu(o)
    # important! DO NOT add otus like group.otus << otu, it WILL NOT WORK
    return false if !o.is_a?(Otu)
    if !self.otus.include?(o)
      self.otu_groups_otus.create(:otu_id => o.id)
      self.save

      self.mxes.each do |m|
        if !m.mxes_otus.include?(Otu.find(o.id))
          m.mxes_otus.create(:otu_id => o.id, :mx_id => self.id)
          m.save
        end
      end
      true
    else
      false
    end
  end

  def remove_otu(o)
    return false if !o.is_a?(Otu)
    # this is tricky, we want to fire the :before_destroy on a OtuGroupOtu so that we can sync
    # the matrices so DON'T USE .delete!!

    # this fires the :before_destroy in OtuGroupsOtu as well, otus are removed from matrices there
    OtuGroupsOtu.find_by_otu_id_and_otu_group_id(o.id, self.id).destroy
  end

    def position_otu(o, acts_as_list_method)
    false
  end

  def display_name(options = {})
    name
  end

  def contents(content_template) # :yields: {Otu => content_b_otu}
    otus.inject({}){|hsh, o| hsh.merge!(o => content_template.content_by_otu(o))}
  end

  def specimens
    self.otus.inject([]){|sum, o| sum << o.specimens_most_recently_determined_as}.flatten.uniq
  end

  def collecting_events
    (self.specimens.collect{|s| s.ce}.compact + self.lots.collect{|s| s.ce}.compact).uniq
  end

  def mappable_specimens
    self.otus.inject([]){|sum, o| sum << Specimen.with_current_determination(o).that_are_mappable}.flatten.uniq
  end

  def gmaps_markers
    mappable_specimens.inject([]){|ary, s| ary << s.ce.gmap_hash.update({:specimen => s.display_name(:type => :identifiers)}) }
  end

  def extracts # :yields: Array of Extracts
    self.otus.inject([]){|sum, o| sum += o.extracts}.flatten.uniq.sort{|a,b| a.id <=> b.id}
  end

  def genes  # :yields: Array of Strings (Gene names)
    self.otus.collect{|o|
      o.extracts.inject([]){|sum, e| sum += e.pcrs}.collect{|p| p.gene_name_array}}.flatten.uniq.sort{|a,b| a.name <=> b.name
    }
  end

  # TODO: move to named scope for OTUs @proj.otus.not_in_groups
  def self.otus_without_groups(proj)
    Otu.find_by_sql(["SELECT DISTINCT o.* FROM otus AS o LEFT JOIN otu_groups_otus AS ogo ON o.id = ogo.otu_id
    WHERE (((ogo.otu_group_id) Is Null) AND ((o.proj_id)=?));", (proj)])
  end

  def self.find_for_auto_complete(value)
    value.downcase!
    OtuGroup.find(:all, :conditions => ["proj_id = ? and (name like ? or name like ? or name like ?)", @proj.id, "#{value}%", "%#{value}%", "%#{value}"])
  end

  private

  # called on before_destroy
  def update_matrices
    self.mxes.each do |m|
      m.remove_group(self)
    end
  end

end
