# == Schema Information
# Schema version: 20090930163041
#
# Table name: content_types
#
#  id         :integer(4)      not null, primary key
#  sti_type   :string(255)
#  is_public  :boolean(1)
#  name       :string(255)
#  can_markup :boolean(1)      default(TRUE)
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class ContentTypeTest < ActiveSupport::TestCase

  require 'content_type'

  def setup
    set_before_filter_vars
  end

  def test_create
    # work here ...
    c = ContentType.new
    assert !c.valid?, 'content_type is not valid without a name'  # not valid without a name
    assert_equal 'ContentType::TextContent', c.sti_type
    c.name = "foo"
    assert c.valid?
    assert c.save
    c.reload
  end

  def build_some_content_and_stuff
    @ct = ContentType::TextContent.new(:name => 'foo')
    @ct.save # can't use create!, we set the type if nil on validation
    assert_equal ContentType::TextContent, @ct.class
    @ct.reload
    assert_equal 0, @ct.mapped_chr_groups.count

    @cg1 = ChrGroup.create!(:name => 'cg1')
    @cg2 = ChrGroup.create!(:name => 'cg2')

    @chr1 = Chr.create!(:name => 'chr_1')
    @chr2 = Chr.create!(:name => 'chr_2')
    @chr3 = Chr.create!(:name => 'chr_3')
    @chr4 = Chr.create!(:name => 'chr_4')

    @chr1.chr_states << ChrState.new(:name => 'foo', :state => '0' )
    @chr1.chr_states << ChrState.new(:name => 'bar', :state => '1' )

    @chr2.chr_states << ChrState.new(:name => 'blorf', :state => '0' )
    @chr2.chr_states << ChrState.new(:name => 'stuff', :state => '1' )

    @chr3.chr_states << ChrState.new(:name => 'zip', :state => '0' )
    @chr3.chr_states << ChrState.new(:name => 'zap', :state => '1' )

    @chr4.chr_states << ChrState.new(:name => 'first', :state => '0' )
    @chr4.chr_states << ChrState.new(:name => 'second', :state => '1' )

    @cg1.add_chr(@chr1)
    @cg1.add_chr(@chr2)
    @cg2.add_chr(@chr3)
    @cg2.add_chr(@chr4)

    @cg1.reload
    @cg2.reload

    @o1 = Otu.create!(:name => 'first')
    @o2 = Otu.create!(:name => 'second')

    @c1 = Coding.new(:otu_id => @o1.id, :chr_id => @chr1.id, :chr_state_id => @chr1.chr_states[0].id)
    @c2 = Coding.new(:otu_id => @o1.id, :chr_id => @chr2.id, :chr_state_id => @chr2.chr_states[0].id)
    @c3 = Coding.new(:otu_id => @o1.id, :chr_id => @chr3.id, :chr_state_id => @chr3.chr_states[0].id)
    @c4 = Coding.new(:otu_id => @o1.id, :chr_id => @chr4.id, :chr_state_id => @chr4.chr_states[0].id)
    @c5 = Coding.new(:otu_id => @o1.id, :chr_id => @chr1.id, :chr_state_id => @chr1.chr_states[1].id)

    [@c1, @c2, @c3, @c4, @c5].each do |c|
      c.save!
    end

    [@o1, @o2, @chr1, @chr2, @chr3, @chr4, @ct].each do |o|
      o.reload
    end

    assert_equal 2, @cg1.chrs.count
    assert_equal 2, @cg2.chrs.count
  end

  def test_map_to_chr_group
    build_some_content_and_stuff
    @ct.mapped_chr_groups << @cg1
    @ct.mapped_chr_groups << @cg2
    @ct.reload
    assert_equal 2, @ct.mapped_chr_groups.size
    assert_equal @cg1, @ct.mapped_chr_groups[0]
  end

  def test_chrs
    build_some_content_and_stuff
    @ct.mapped_chr_groups << @cg1
    @ct.mapped_chr_groups << @cg2
    @ct.reload
    assert_equal 4, @ct.chrs.size
    assert_equal [@chr1, @chr2, @chr3, @chr4], @ct.chrs
  end

  # this doesn't work because chr_group order is determined by proj, so it is the same as in test_chrs
  def dont_test_chrs_ordered_differently
    build_some_content_and_stuff
    @ct.mapped_chr_groups << @cg2
    @ct.mapped_chr_groups << @cg1
    @ct.reload
    # assert_equal [@chr3, @chr4, @chr1, @chr2], @ct.chrs
  end

  def test_codings_by_otu
    build_some_content_and_stuff
    @ct.mapped_chr_groups << @cg1
    @ct.reload
    assert_equal [[@chr1, [@c1, @c5]], [@chr2,[@c2]]], @ct.codings_by_otu(@o1)
    @ct.mapped_chr_groups << @cg2
    @ct.reload
    assert_equal [[@chr1,[@c1, @c5]], [@chr2,[@c2]], [@chr3,[@c3]], [@chr4,[@c4]]], @ct.codings_by_otu(@o1)
  end

  def test_natural_language_by_otu
    build_some_content_and_stuff
    @ct.mapped_chr_groups << @cg1
    @ct.reload
    assert_equal "chr_1: foo; bar. chr_2: blorf.", @ct.natural_language_by_otu(@o1)
  end

  def test_natural_language_by_otu_with_a_chr_not_coded
    build_some_content_and_stuff
    @cg1.add_chr(Chr.create!(:name => 'chr_5'))
    @ct.mapped_chr_groups << @cg1

    @ct.reload
    assert_equal "chr_1: foo; bar. chr_2: blorf. chr_5: NOT CODED.", @ct.natural_language_by_otu(@o1)
  end

end


class ContentType::TextContentTest < ActiveSupport::TestCase
 # fixtures :content_types

  def setup
    # gets around has_standard_fields
    $proj_id = 1
    $person_id = 1
  end

  def test_create
    c = ContentType::TextContent.new
    assert !c.valid?
    c.name = 'foo'
    assert c.valid?
    assert c.save!
    assert_equal 'ContentType::TextContent', c.sti_type
    assert_equal '/content/c', c.partial
    assert_equal c.partial, c.public_partial
  end

  def test_that_subclasses_have_required_methods_and_partials

    ContentType::BUILT_IN_TYPES.each do |i| # for each custom content type
      ct = i.constantize.create! # (:sti_type => i)

      # assert that the necessary methods exist
      assert_equal i, ct.class.to_s
      assert_equal true, !ct.partial.blank?
      assert_equal true, !ct.public_partial.blank?
      assert_equal true, !ct.display_name.blank?
      assert_equal true, !ct.class.description.blank?

      # and that the partials they point to exist

      # I want verbosity, thus the raise, which kills the whole process, gladly do it another way
      # if I can figure out how to dump messages to the screen
      t = "#{Rails.root.to_s}/app/views#{ct.partial.reverse.gsub(/(\/+(.*))/, "_\\1").reverse}.html.erb"
      File.exist?(t) || raise("missing file #{t}")
      t = "#{Rails.root.to_s}/app/views#{ct.public_partial.reverse.gsub(/(\/+(.*))/, "_\\1").reverse}.html.erb"
      File.exist?(t) || raise("missing file #{t}")

      if ct.renders_as_text?
        t = "#{Rails.root.to_s}/app/views#{ct.public_partial.reverse.gsub(/(\/+(.*))/, "_\\1").reverse}_text.html.erb"
        File.exist?(t) || raise("missing _text partial of ContentType #{ct.display_name}, file #{t}")
      end

    end
  end

  def test_create_if_needed
    custom_subclass = ContentType::BUILT_IN_TYPES[0]

    x = ContentType.create_if_needed(custom_subclass, $proj_id)
    assert_equal x.sti_type, ContentType::BUILT_IN_TYPES[0]
    assert x.destroy

    # other usage
    t = ContentType::BUILT_IN_TYPES[0].constantize.create!
    assert_equal t.sti_type, ContentType::BUILT_IN_TYPES[0]

    # it's already created - so return the created result
    s = ContentType.create_if_needed(custom_subclass, $proj_id)
    assert_equal s, t
    assert_equal s.sti_type, ContentType::BUILT_IN_TYPES[0]
  end

  def test_create_many_text_types
    $proj_id = 837
    ContentType.create!(:name => 'foo')
    ContentType.create!(:name => 'bar')
    ContentType.create!(:name => 'blorf')
    assert_equal 3, ContentType.find_all_by_proj_id($proj_id).size
  end

  def test_attempt_to_create_built_in_type_two_times_in_project_fails
    assert ContentType::BUILT_IN_TYPES[0].constantize.create!
    c = ContentType::BUILT_IN_TYPES[0].constantize.new
    assert !c.valid?
  end
end

class ContentType::GmapContentTest < ActiveSupport::TestCase
 # fixtures :content_types

  def setup
    # gets around has_standard_fields
    $proj_id = 1
    $person_id = 1
  end

  def test_create
    c = ContentType::GmapContent.new
    assert c.valid?
    assert c.save
    c.reload
    assert_equal 'ContentType::GmapContent', c.sti_type
    assert_equal '/otus/page/gmap', c.partial
    assert !c.display_name.blank?
  end
end
