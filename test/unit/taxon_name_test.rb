# == Schema Information
# Schema version: 20090930163041
#
# Table name: taxon_names
#
#  id                     :integer(4)      not null, primary key
#  name                   :string(255)     not null
#  author                 :string(128)
#  year                   :string(4)
#  nominotypical_subgenus :boolean(1)
#  parent_id              :integer(4)
#  valid_name_id          :integer(4)
#  namespace_id           :integer(4)
#  external_id            :integer(4)
#  taxon_name_status_id   :integer(4)
#  l                      :integer(4)
#  r                      :integer(4)
#  orig_genus_id          :integer(4)
#  orig_subgenus_id       :integer(4)
#  orig_species_id        :integer(4)
#  iczn_group             :string(8)
#  type_type              :string(255)
#  type_count             :integer(4)
#  type_sex               :string(255)
#  type_repository_id     :integer(4)
#  type_repository_notes  :string(255)
#  type_geog_id           :integer(4)
#  type_locality          :text
#  type_notes             :string(255)
#  type_taxon_id          :integer(4)
#  type_by                :string(64)
#  type_lost              :boolean(1)
#  ref_id                 :integer(4)
#  page_validated_on      :integer(4)
#  page_first_appearance  :integer(4)
#  notes                  :text
#  import_notes           :text
#  display_name           :string(255)
#  creator_id             :integer(4)      not null
#  updator_id             :integer(4)      not null
#  updated_on             :timestamp       not null
#  created_on             :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class TaxonNameTest < ActiveSupport::TestCase
 
  self.use_instantiated_fixtures  = true
  
  fixtures :taxon_names, :images
  
  def setup
    $person_id = 1
    $proj_id = 11
    @bill = TaxonName.new(:name => "Bill", :iczn_group => "genus", :year => '1900')
  end
 
  def test_get_parent_name
    @t =  TaxonName.find(1)
    assert_equal "Papa", @t.get_parent_name('genus')
  end
  
  def test_get_parent_name1
    @t =  TaxonName.find(3)
    assert_equal "Papa", @t.get_parent_name('family')
  end
 
  def test_get_parent_name2
    @t =  TaxonName.find(3)
    assert_equal "Papa", @t.get_parent_name('subgenus') # odd behaviour
  end
  
  def test_name_at_rank
    @t = TaxonName.find(5)
    assert_equal "", @t.name_at_rank('subgenus')
  end
  
  def test_name_at_rank_genus
    @t = TaxonName.find(5)
    assert_equal "Charles", @t.name_at_rank('genus')
  end
  
    def test_obj_at_rank2 # in our fixtures the family is the top level, so its nil!!
    @t = TaxonName.find(3)
    assert_equal nil, @t.obj_at_rank('family')
  end

  def test_obj_at_rank
    @t = TaxonName.find(5)
    assert_equal TaxonName.find(3), @t.obj_at_rank('genus')
  end

  def test_get_parent
    assert_equal nil, @bill.parent
    assert @bill.save
    assert_equal nil, @bill.parent
  end
  
  def test_full_set
    nodes = @child_right.full_set
    assert_equal 4, nodes.size
    assert nodes.include?(@child_right)
    assert nodes.include?(@g_child_4)
    assert nodes.include?(@g_child_5)
    assert nodes.include?(@gg_child)
    nodes = @child_middle.full_set
    assert_equal 4, nodes.size
    nodes = @child_left.full_set
    assert_equal 1, nodes.size
  end
  
  def test_create_without_parent
    @bill.save
    @bill.reload
    assert_equal 1, @bill.l
    assert_equal 2, @bill.r
    assert_equal nil, @bill.parent_id
  end

  def test_space_in_name_is_not_allowed
    @bill.name = "foo bar"
    @bill.save
    assert_equal true, !@bill.valid?
    assert @bill.errors[:name].any? 
  end

  # tests the method that both creates new and sets parent

  def test_create_new
    @bill.save # gives us a root
    @bill.reload

    person = Person.find(1)
    person.editable_taxon_names << @bill
    person.reload
    # let Person edit the root. 

    assert_equal 0, @bill.children.size
    @foo = TaxonName.create_new(
      :taxon_name => {:name => "Bob", :iczn_group => "genus", :year => '1910', :parent_id => @bill.id},
      :person => person)
    
    @foo.reload
    @bill.reload
    assert_equal @bill, @foo.parent
    assert_equal "Bob", @foo.name
    assert_equal 1, @bill.children.size
  end

  def test_create_new_without_person_fails
    @bill.save # gives us a root
    @bill.reload
    assert_equal 0, @bill.children.size
    @foo = TaxonName.create_new(:taxon_name => {:name => "Bob", :iczn_group => "genus", :year => '1910', :parent_id => @bill.id})
    assert_equal "Invalid or no person provided.", @foo.errors['base'].first
    # need another test 
  end

  def test_assign
    @bill.l = 42
    assert 42 != @bill.l
    @bill.r = 85
    assert 85 != @bill.r
    assert @bill.save
    @bill.reload
    assert_equal 1, @bill.l
    assert_equal 2, @bill.r   
  end
    
  def test_check_subtree
    assert @root_node.check_subtree
    # need to use update_all to get around attr_protected
    TaxonName.update_all("r = #{@root_node.l + 1}", "id = #{@root_node.id}")
 #  tns = TaxonName.find(:all, :order => "l")
 #  puts "\n"
 #  tns.each do |t|
 #    puts "#{t.l}, #{t.r}, id: #{t.id}, parent: #{t.parent_id}"
 #  end
    assert !@root_node.reload.check_subtree 
    assert taxon_names(:child_right).check_subtree
    TaxonName.update_all("l = 17", "id = #{taxon_names(:gg_child).id}")
    assert !taxon_names(:child_right).reload.check_subtree
    TaxonName.update_all("r = 18", "id = #{taxon_names(:gg_child).id}")
    assert taxon_names(:gg_child).check_subtree
  end
  
  def test_check_all_1
    assert TaxonName.check_all
    # need to use update_all to get around attr_protected
    TaxonName.update_all("l = 3", "id = #{taxon_names(:child_middle).id}")
    assert !TaxonName.check_all
  end
  
  def test_check_all_2
    TaxonName.slide(2, 10)
    assert !TaxonName.check_all    
  end
  
  def test_check_all_3
    TaxonName.slide(1, 11)
    assert !TaxonName.check_all
  end
  
  def test_renumber_all_1
    TaxonName.update_all "l = NULL, r = NULL"
    assert !TaxonName.check_all
    assert TaxonName.renumber_all
    @root_node.reload
    @child_middle.reload
    assert_equal 1, @root_node.left
    assert_equal 20, @root_node.right
    assert_equal 4, @child_middle.left
    assert_equal 11, @child_middle.right
    assert TaxonName.check_all
  end
  
  def test_renumber_all_2
    @g_child_4.move(@gg_child)
    TaxonName.find(:all).each { |t|
      t.left = ''
      t.right = ''
      t.save!
      t.reload
    }
    assert !TaxonName.check_all
    assert TaxonName.renumber_all
    @root_node.reload
    @child_middle.reload
    @g_child_4.reload
    assert_equal 1, @root_node.left
    assert_equal 20, @root_node.right
    assert_equal 4, @child_middle.left
    assert_equal 11, @child_middle.right
    assert_equal 15, @g_child_4.left
    assert_equal 16, @g_child_4.right
    assert TaxonName.check_all    
  end
    
  
  def test_find_insertion_point
    @bill.save
    assert_equal 3, @bill.find_insertion_point(@root_node)
    assert_equal 4, @bill.find_insertion_point(@child_middle)
    @aalfred = TaxonName.new(:name => "Aaalfred", :iczn_group => "genus", :year => '1984')
    @aalfred.save
    assert_equal 1, @aalfred.find_insertion_point(@root_node)
    assert_equal 2, @aalfred.find_insertion_point(@child_left)
    assert_equal 12, @aalfred.find_insertion_point(@child_right)
    @zed = TaxonName.new(:name => "Zed", :iczn_group => "genus", :year => '1984')
    @zed.save
    assert_equal 19, @zed.find_insertion_point(@root_node)
    assert_equal 17, @zed.find_insertion_point(@g_child_5)
    assert_equal 16, @zed.find_insertion_point(@gg_child)
    assert_equal 10, @child_right.find_insertion_point(@child_middle)
  end
  
  #* need to check that the scope constraint is working
  
  def test_slide_1
    TaxonName.slide(2, 3)
    assert_equal 6, @child_middle.reload.l
    TaxonName.slide(-2, 3)
    assert @root_node.reload.check_subtree
  end
  
  def test_slide_2
    TaxonName.slide(8, 10)
    assert_equal 19, @child_middle.reload.r
    assert_equal 20, @child_right.reload.l
  end

  def test_set_parent_1
    assert_raise(RuntimeError) { @bill.set_parent(@root_node) }    
    assert_raise(RuntimeError) { @root_node.set_parent(@root_node) }    
    assert_raise(RuntimeError) { @g_child_2.set_parent(@root_node) }    
    assert @bill.save
    assert @root_node.reload.check_subtree
    assert @bill.set_parent(@root_node)
    assert_equal @root_node, @bill.parent
    assert_equal 4, @bill.l
    assert_equal 5, @bill.r
    assert_equal 3, @child_left.reload.r
    assert_equal 6, @child_middle.reload.l
    assert_equal 22, @root_node.reload.r
    assert @root_node.reload.check_subtree
  end
  
  def test_set_parent_2
    assert @root_node.check_subtree
    assert @bill.save
    assert @bill.set_parent(@gg_child)
    assert_equal @gg_child, @bill.parent
    assert_equal 17, @bill.l
    assert_equal 18, @bill.r
    assert_equal 16, @gg_child.reload.l
    assert_equal 19, @gg_child.reload.r
    assert_equal 15, @g_child_5.reload.l
    assert_equal 20, @g_child_5.reload.r
    assert_equal 21, @child_right.reload.r
    assert @g_child_5.reload.check_subtree
    assert @child_right.reload.check_subtree
    assert @root_node.reload.check_subtree
  end

  def test_set_parent_3
    assert @bill.save
    assert @bill.set_parent(@child_middle)
    assert @root_node.reload.check_subtree
  end
  
  def test_move_1
    @child_right.move(@child_middle)
    assert_equal @child_middle, @child_right.reload.parent
    assert_equal 1, @root_node.reload.l
    assert_equal 20, @root_node.reload.r
    assert_equal 4, @child_middle.reload.l
    assert_equal 19, @child_middle.reload.r
    assert @root_node.reload.check_subtree
  end
  
  def test_move_2
    assert_raise(RuntimeError) { @child_middle.move(@g_child_2) } # can't set a current child as the parent-- creates a loop
    @child_left.move(@g_child_1)
    @child_right.move(@child_left)
    
    assert_raise(RuntimeError) {@gg_child.move(@root_node)} # moving species to family is now bad
    
    assert_equal 5, @child_left.parent_id
    assert_equal 2, @child_right.parent_id
    # assert_equal 1, @gg_child.parent_id
    @child_middle.reload
    @gg_child.reload
    # assert_equal 19, @gg_child.r
    assert_equal 19, @child_middle.r
    assert_equal 2, @child_middle.l
    @root_node.reload
    assert @root_node.check_subtree
    @child_right.move(@root_node)
    @gg_child.move(@g_child_5)
    @child_left.move(@root_node)
    @taxon_names.each { |foo|
      fx = foo[1]
      tn = TaxonName.find(fx['id'])
      assert_equal fx['parent_id'], tn.parent_id
      assert_equal fx['l'], tn.l
      assert_equal fx['r'], tn.r
    }
  end
  
  def test_destroy
    # assumes nodes with children are protected from deletion
    assert_raise(RuntimeError) { @g_child_5.destroy }
    assert @root_node.reload.check_subtree
 
  # tns = TaxonName.find(:all, :order => "name")
  # puts "\n"
  # tns.each do |t|
  #   puts "#{t.l}, #{t.r}, id: #{t.id}, parent: #{t.parent_id}"
  # end
    
    assert @gg_child.reload.destroy    
    assert @root_node.reload.check_subtree
    @g_child_5.reload
    assert @g_child_5.children.empty?
    assert @g_child_5.destroy
    @child_right = TaxonName.find(4)
    assert_equal 15, @child_right.r
    assert @root_node.reload.check_subtree
  end
  
# def test_permissions
#   $person_id = 2
#   assert_raise(RuntimeError) {@gg_child.save}
#   assert @child_left.save
#   assert @g_child_2.save
#   assert_raise(RuntimeError) {@gg_child.destroy}
#   assert @child_left.destroy
#   assert @g_child_2.destroy
#   $person_id = 1
# end
    
  
  #* this is broken for unknown reasons. will need to fix if we allow the deletion of nodes with children
  # test pruning a branch. only works if we allow the deletion of nodes with children
# def test_destroy_2
#   ActiveRecord::Base.logger.error "Begin middle_child destroy"
#   assert @child_middle.destroy
#   ActiveRecord::Base.logger.error "End middle_child destroy"
#   @root_node = TaxonName.find(1)
#   assert_equal 2, @root_node.children.size
#   @child_left = TaxonName.find(2)
#   @child_right = TaxonName.find(4)
#   assert_equal 0, TaxonName.find(:all, :conditions => "id > 4 and id < 8").size # were the children deleted?
#   assert_equal 6, TaxonName.find(:all).size
#   assert_equal 3, @child_left.r
#   assert_equal 4, @child_right.l
#   assert_equal 6, @root_node.r
#   assert @root_node.check_subtree
# end
  
  def test_image_descriptions
    assert TaxonName.renumber_all
    @root_node.reload
    @child_middle.reload

    @otu1 = Otu.create!(:taxon_name => @child_middle)
    
    @id1 = ImageDescription.create!(:otu => @otu1, :image => Image.find(1))
    
    assert_equal 1, @child_middle.image_descriptions(6).size
    assert_equal @id1, @child_middle.image_descriptions(6)[0]
    
    # assert that the tree is unchanged
    assert_equal 1, @root_node.left
    assert_equal 20, @root_node.right
    assert_equal 4, @child_middle.left
    assert_equal 11, @child_middle.right
    assert TaxonName.check_all
  end

  def test_display_author_year
    @ref = Ref.new(:year => '1920', :title => "Dark and Storm Night")
    auth = Author.new(:last_name => 'Frank')
    auth2 = Author.new(:last_name => "Enstein")
    @ref.authors << auth
    @ref.authors << auth2
    assert @ref.save
    
    @root = TaxonName.new(:name => "root", :iczn_group => "n/a", :ref => @ref)
    assert @root.save!
    @root.reload
    assert_equal "Frank and Enstein, 1920", @root.display_author_year
    assert @root.check_subtree
    
    @family_name_with_no_ref_or_author_but_with_year =  TaxonName.new(:name => "Familiidae", :iczn_group => "family", :year => '1900')
    assert @family_name_with_no_ref_or_author_but_with_year.save
    assert_equal true, @family_name_with_no_ref_or_author_but_with_year.set_parent(@root) # note how we need to set the parent
    assert_equal @root.id, @family_name_with_no_ref_or_author_but_with_year.parent.id
    assert_equal "author not provided, 1900", @family_name_with_no_ref_or_author_but_with_year.display_author_year

    # logic is given author year over-rides reference author year!
    @genus_name_with_ref_and_author_year = TaxonName.new(:name => "Bill", :iczn_group => "family", :year => '1900', :author => "Jekyl", :ref => @ref)
    assert_equal true, @genus_name_with_ref_and_author_year.save
    assert_equal true, @genus_name_with_ref_and_author_year.set_parent(@family_name_with_no_ref_or_author_but_with_year)  
    assert_equal "Jekyl, 1900", @genus_name_with_ref_and_author_year.display_author_year
    
    @genus_name_with_nothing = TaxonName.new(:name => "Nothing", :iczn_group => "genus")
    assert @genus_name_with_nothing.save
    assert_equal true, @genus_name_with_nothing.set_parent(@family_name_with_no_ref_or_author_but_with_year)
    assert_equal "", @genus_name_with_nothing.display_author_year
    
    @species_name_in_originally_described_genus =  TaxonName.new(:name => "bill", :iczn_group => "species", :year => '1900', :author => "Jekyl")
    assert @species_name_in_originally_described_genus.save!
    assert_equal true, @species_name_in_originally_described_genus.set_parent(@genus_name_with_nothing)
    assert_equal "Jekyl, 1900", @species_name_in_originally_described_genus.display_author_year
    
    @transfered_species_name =  TaxonName.new(:name => "bill", :iczn_group => "species", :year => '1900', :author => "Jekyl", :orig_genus_id => @genus_name_with_ref_and_author_year.id )
    assert @transfered_species_name.save
    assert_equal true, @transfered_species_name.set_parent(@genus_name_with_nothing)
    assert_equal '(Jekyl, 1900)', @transfered_species_name.display_author_year

    # @tribe_name_with_nothing = TaxonName.new(:name => "Pantolytini", :iczn_group => "family", :author => "", :year => "") # shouldn't be allowed to have "" not nil
    # assert @tribe_name_with_nothing.save
    # assert_equal true, @tribe_name_with_nothing.set_parent(@root)
    # assert_equal '', @tribe_name_with_nothing.display_author_year
  end
  
  def test_genus_is_capitalized
    p = Person.find($person_id)
    t = TaxonName.create_new(:person => p, :taxon_name => {:name => 'foo', :iczn_group => 'genus', :parent_id => 3})
    assert !t.valid?
    t.name = 'Foo'
    assert t.valid?
  end

  def test_family_is_capitalized
    p = Person.find($person_id)
    t = TaxonName.create_new(:person => p, :taxon_name => {:name => 'fooinae', :iczn_group => 'family', :parent_id => 1})
    assert !t.valid?
    t.name = 'Fooinae'
    assert t.valid?
  end
 
  # always true? very old names?
  def test_species_names_are_lowercased
    p = Person.find($person_id)
    t = TaxonName.create_new(:person => p, :taxon_name => {:name => 'Blorf', :iczn_group => 'species', :parent_id => 2})
    assert !t.valid?
    t.name = 'blorf'
    assert t.valid?
  end

  def test_that_no_underscores_are_present_in_latinized_names
    p = Person.find($person_id)
    t = TaxonName.create_new(:person => p, :taxon_name => {:name => 'blo_rf', :iczn_group => 'species', :parent_id => 2})
    assert !t.valid?
    t.name = 'blorf'
    assert t.valid?
  end
 
  def test_that_no_punctuation_is_present
    p = Person.find($person_id)
    t = TaxonName.create_new(:person => p, :taxon_name => {:name => 'blof!', :iczn_group => 'species', :parent_id => 2})
    assert !t.valid?
    t.name = 'blof'
    assert t.valid?
  end

  test 'that species names have genus group parents' do 
    p = Person.find($person_id)
    t = TaxonName.create_new(:person => p, :taxon_name => {:name => 'blof', :iczn_group => 'species', :parent_id => 1}) # 1 (fixture) is a family group name
    assert_equal false, t.valid?
    assert t.move(TaxonName.find(3))
    assert t.valid?
  end 

  # ICZN vs. others?
  def test_family_names_end_in_legal_ending
  end

  def test_display_name_species_index_url
    create_a_species_epithet
    assert_equal 'http://speciesindex.org/iczn/gen/Foo/1800', @gen.species_index_url
    assert_equal 'http://speciesindex.org/iczn/subgen/Foo/Bar/1850', @subgen.species_index_url
    assert_equal 'http://speciesindex.org/iczn/sp/Foo/stuff', @sp.species_index_url # update with subgen if necessary
    assert_equal 'http://speciesindex.org/iczn/subsp/Foo/stuff/things/1865', @subsp.species_index_url
  end 

  protected

  def create_a_species_epithet 
    @root = TaxonName.new(:name => "Fooidae", :iczn_group => "family", :year => '1900')
    
    @root.save # gives us a root
    @root.reload

    person = Person.find(1)
    person.editable_taxon_names << @root
    person.reload
    # let Person edit the root

    @gen = TaxonName.create_new(
      :taxon_name => {:name => "Foo", :iczn_group => "genus", :year => '1800', :parent_id => @root.id},
      :person => person)
    @gen.reload
    @subgen = TaxonName.create_new(
      :taxon_name => {:name => "Bar", :iczn_group => "genus", :year => '1850', :parent_id => @gen.id},
      :person => person)
    @subgen.reload   
    @sp = TaxonName.create_new(
      :taxon_name => {:name => "stuff", :iczn_group => "species", :year => '', :parent_id => @subgen.id},
      :person => person)
    @sp.reload
    @subsp = TaxonName.create_new(
      :taxon_name => {:name => "things", :iczn_group => "species", :year => '1865', :parent_id => @sp.id},
      :person => person)
    @subsp.reload

    @root.reload
  end

end
