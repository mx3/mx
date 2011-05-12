require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'yaml'

class LinkerTest < ActiveSupport::TestCase

  def setup
    # set Project and Person ids
    set_before_filter_vars
    @proj = Proj.find($proj_id)
    @proj.labels.destroy_all
    @ref_stub = Ref.create!

    @text = "This is a head, it has no flipper, does it?  The green hair on the head is ugly."  # 18 total words, 14 unique 
    %w(head flipper hair).each do |w|
      Label.create!(:name => w)
    end
    @proj.reload
  end

  ## Database (mx) agnostic tests

  def test_all_words_on_vanilla_init
    create_a_basic_linker
    assert_equal Linker, @l.class
    foo = @l.all_words
    assert_equal %w(this is a head it has no flipper does the green hair on ugly), foo   # removes dupes, but doesn't sort
    assert_equal 14, foo.size 
  end

  def test_all_words_on_init_with_minimum_word_size_3
    @l = Linker.new(:proj_id => @proj.id, :incoming_text => @text, :minimum_word_size => 3)
    foo = @l.all_words
    assert_equal %w(this head has flipper does the green hair ugly), foo   
    assert_equal 9, foo.size 
  end

  # we now split on sentences and don't fuse across them
  def test_all_words_init_with_minimum_word_size_3_and_adjacent_words_to_fuse_1
    @l = Linker.new(:proj_id => @proj.id, :incoming_text => @text, :minimum_word_size => 3, :adjacent_words_to_fuse => 1)
    foo = @l.all_words
    assert_equal %w(this head has flipper does the green hair ugly) + ["flipper does", "the green", "green hair", "the head"], foo   
    assert_equal 13, foo.size 
  end

  def test_all_words_init_with_adjacent_words_to_fuse_2
    @l = Linker.new(:proj_id => @proj.id, :incoming_text => "one two three", :adjacent_words_to_fuse => 2)
    assert_equal ["one", "two", "three", "one two", "two three", "one two three"], @l.all_words
  end

  def test_common_words_are_stricken_when_requested
    @l = Linker.new(:proj_id => @proj.id, :incoming_text => "one two three", :adjacent_words_to_fuse => 2, :exclude_common_words => true , :common_words => %w(two))
    assert_equal ["one",  "three" ], @l.all_words
  end

  ## Database (mx) required tests

  # #link_set in this form allows blank definitions but refects abbreviations/acronyms
  def test_link_set_from_vanilla_linker
    create_a_basic_linker
    w = @l.link_set(:proj_id => 1)
    assert_equal 3, w.size
  end

  def test_unmatched_from_vanilla_linker
    create_a_basic_linker
    assert_equal ["a", "does", "green", "has", "is", "it", "no", "on", "the", "this", "ugly"], @l.unmatched(:proj_id => 1)
    assert_equal 11, @l.unmatched(:proj_id => 1).size
  end

  def test_link_set_with_labels_excluding_definitions
    create_a_basic_linker
    create_a_bunch_more_labels_with_definitions
    assert_equal 2, Proj.find(1).labels.size
    assert_equal 2, @l.link_set(:proj_id => 1).size
    assert_equal 1, @l.link_set( :proj_id => 1, :exclude_blank_descriptions => true ).size
  end

  # "plural form" Keyword + Tag related
  def test_link_set_matches_on_multiple_words
    clear_proj_labels
    p = Label.create!(:name => "foo bar")

    # for each additional potential word we need to link an adjacent word ... HMMM
    @linker = Linker.new(:proj_id => @proj.id, :incoming_text => "foo bar", :adjacent_words_to_fuse => 2)
    assert_equal p, @linker.link_set(:proj_id => 1).first
  end

  def test_unmatched_with_plural_tags
    setup_for_plural_tests
    txt = "This cow is one of many foos, but doesn't know bars."
    @linker = Linker.new(:proj_id => @proj.id, :incoming_text => txt) # :include_plural => true by default
    assert_equal ["but", "cow", "doesn't", "is", "know", "many", "of", "one", "this"], @linker.unmatched(:proj_id => @proj.id)
  end

  def test_that_plural_tags_match
    setup_for_plural_tests
    # this should return matches to foo and bar 
    txt = "This cow is one of many foos.  Not all bars are cats."
    @linker = Linker.new(:proj_id => @proj.id, :incoming_text => txt)
    # should match foos and bars to foo and bar
    assert_equal 2, @linker.link_set(:proj_id => 1).size # includes plural by default
  end

  def test_that_plural_tags_link
    setup_for_plural_tests
    # this should return matches to foo and bar 
    txt = "This cow is one of many foos.  Not all bars are cats."
    @linker = Linker.new(:proj_id => @proj.id, :incoming_text => txt, :include_plural => true)

    # assert_equal "FOO", @linker.linked_text(:proj_id => 1) 
    assert @linker.linked_text(:proj_id => 1) =~ /\>bars\</
    assert @linker.linked_text(:proj_id => 1) =~ /\>foos\</
  end

  def test_that_plural_tags_work_with_singular_when_linking
    setup_for_plural_tests
    # this should return matches to foo and bar 
    txt = "Foo is one of many foos.  Not all bars are cats."
    @linker = Linker.new(:proj_id => @proj.id, :incoming_text => txt, :include_plural => true)

    #  assert_equal "FOO", @linker.linked_text(:proj_id => 1) 
    assert @linker.linked_text(:proj_id => 1) =~ /\>foo\</i
    assert @linker.linked_text(:proj_id => 1) =~ /\>bars\</i
    assert @linker.linked_text(:proj_id => 1) =~ /\>foos\</i
  end

  def test_that_terms_with_two_or_more_words_match_while_plural_true
    clear_proj_labels

    @labels = []
    ["foo bar", "foo", "bar", "stuff thing"].each_with_index do |w,i|
      @labels[i] = Label.create!(:name => w) # , :description => "FOO!")  
    end

    ["foo bar", "foo", "bar", "stuff thing"].each_with_index do |w,i|
      Label.create!(:name => "#{w}s", :plural_of_label => @labels[i]) # TODO: check this, :description => "FOO!", :is_acronym => false)  
    end

    @labels[0..3].each do |l|
      oc = OntologyClass.create(:written_by => @ref_stub, :definition => "def for #{l.name}")
      Sensu.create!(:ontology_class => oc, :label => l, :ref => @ref_stub)
    end

    txt = "Foo bar is one of many foo bars.  Not all bars are cats. And don't forget stuff things."
    @linker = Linker.new(:proj_id => @proj.id, :incoming_text => txt, :adjacent_words_to_fuse => 2) # defaults to include plural
    assert_equal "[foo bar] is one of many [foo bars].  Not all [bars] are cats. And don't forget [stuff things].", @linker.linked_text(:proj_id => 1, :mode => 'bracket') 
    # assert_equal "some complicated html markup", @linker.linked_text(:proj_id => 1, :mode => 'mx_link')  # this is working now
  end

  test "literal matches" do
    Label.destroy_all
    txt = "Head with bright blue eye, small antenna, and GIANT teeth.\n  Hind- \n \n wings large and frilly."  
    @labels = []
    ["head", "bright blue eye", "eye", "hindwing", "giant", "frilly"].each_with_index do |w, i|
      @labels[i] = Label.create!(:name => w) 
    end

    @labels.each do |l|
      oc = OntologyClass.create(:written_by => @ref_stub, :definition => "def for #{l.name}")
      Sensu.create!(:ontology_class => oc, :label => l, :ref => @ref_stub)
    end

    result = "[head] with [bright blue eye], small antenna, and [giant] teeth. Hindwings large and [frilly]."
    @linker = Linker.new(:proj_id => @proj.id, :incoming_text => txt, :match_type => :exact, :scrub_incoming => true) 
    assert_equal result, @linker.linked_text(:proj_id => 1, :mode => 'bracket') 
  end

  test "test_tricky_stuff_links" do
    @labels = []
    ["sheet", "elbow", "warehouse", "tergite", "wall", "happy joy", "killjoy", "rainbow", "writing desk", "spot"].each_with_index do |w, i|
      @labels[i] = Label.create!(:name => w) # , :description => "FOO!")  
    end

    @labels[0..4].each_with_index do |l , i|
      @labels.push Label.create!(:name => "#{l.name}s", :plural_of_label => @labels[i])
    end

    @labels[0..9].each do |l|
      oc = OntologyClass.create(:written_by => @ref_stub, :definition => "def for #{l.name}")
      Sensu.create!(:ontology_class => oc, :label => l, :ref => @ref_stub)
    end

    # includes nastieness like injected line returns, dashes etc. 
    txt =     "Elbows are sharp, unlike rainbows. He is such a killjoy because he has never spotted a rain\nbow or a rain-bow. Rainbows are often on bedsheets. Warehouses sell sheets around the elbow. She feels happy joy when sitting at her writing-desk. the terg-\nite was spotted on the wall. There is a sheet on the writing desk.\n\nDo not wear down your writing\n\n\n\n\ndesk.  Termites not tergites. I prefer happy-joy to spots and killjoys. Wall of spots. Writing some of happy desk joy."

    result = "[elbows] are sharp, unlike rainbows. He is such a [killjoy] because he has never spotted a rain\nbow or a rain-bow. Rainbows are often on bedsheets. [warehouses] sell [sheets] around the [elbow]. She feels [happy joy] when sitting at her writing-desk. the terg-\nite was spotted on the [wall]. There is a [sheet] on the [writing desk].\n\nDo not wear down your writing\n\n\n\n\ndesk.  Termites not [tergites]. I prefer happy-joy to spots and killjoys. [wall] of spots. Writing some of happy desk joy."

    @linker = Linker.new(:proj_id => @proj.id, :incoming_text => txt, :include_plural => true, :adjacent_words_to_fuse => 2)
    assert_equal result, @linker.linked_text(:proj_id => 1, :mode => 'bracket') 
    # assert_equal "FOO", @linker.linked_text(:proj_id => 1, :mode => 'link') 
  end

  test "that other tricky embedded stuff links" do
    l = Label.create!(:name => "green hair on the head")
    @proj.labels.each do |l|
      oc = OntologyClass.create(:written_by => @ref_stub, :definition => "def for #{l.name}")
      Sensu.create!(:ontology_class => oc, :label => l, :ref => @ref_stub)
    end
    @proj.reload
    @l = Linker.new(:incoming_text => @text, :proj_id => @proj.id, :adjacent_words_to_fuse => 6)
    # gets us head, flipper, hair, and 'green hair on the head'
    assert_equal 'This is a [head], it has no [flipper], does it?  The [green hair on the head] is ugly.', @l.linked_text(:proj_id => 1, :mode => 'bracket') 
  end

  test 'that homonyms can be returned'  do 
    _stub_some_homonyms_and_synonyms
    create_a_basic_linker
    assert_equal [@flipper, @head], @l.link_set(:result_type => :homonyms).sort{|a,b| a.name <=> b.name} 
  end

  test 'that phrases of more than 2 words match' do
    l = Label.create!(:name => "green hair on the head")
    @l = Linker.new(:incoming_text => @text, :proj_id => @proj.id, :adjacent_words_to_fuse => 6)
    assert_equal Label.find(:all).collect{|l| l.name}.sort, @l.link_set.collect{|l| l.name}.sort
  end

  test 'that some things inside square brackets do not match' do 
    @text = 'string and string [string is a foo string foo] in strings and foostring string.'
    l = Label.create!(:name => 'string')

    @oc = OntologyClass.create!(:definition => 'bar', :written_by => @ref_stub)
    @s = Sensu.create!(:label => l, :ontology_class => @oc, :ref => @ref_stub)

    @l = Linker.new(:incoming_text => @text, :proj_id => @proj.id)
    assert_equal '[string] and [string] [string is a foo string foo] in strings and foostring [string].', @l.linked_text(:proj_id => 1, :mode => 'bracket') 
  end

  test 'that dashes are rendered out properly for link text' do
    @text = 'string and string with a dash- and dash-1 and -one string.'
    l = Label.create!(:name => 'string')
    @oc = OntologyClass.create!(:definition => 'bar', :written_by => @ref_stub)
    @s = Sensu.create!(:label => l, :ontology_class => @oc, :ref => @ref_stub)

    @l = Linker.new(:incoming_text => @text, :proj_id => @proj.id)
    assert_equal '[string] and [string] with a dash- and dash-1 and -one [string].', @l.linked_text(:proj_id => 1, :mode => 'bracket') 

end

private

def _stub_some_homonyms_and_synonyms
  # depends on data from setup
  # make head and flipper homonyms (and synonyms) 
  @head = Label.find_by_name('head')
  @flipper = Label.find_by_name('flipper')

  @oc1 = OntologyClass.create!(:definition => 'foo', :written_by => @ref_stub)
  @oc2 = OntologyClass.create!(:definition => 'bar', :written_by => @ref_stub)

  @s1 = Sensu.create!(:label => @head, :ontology_class => @oc1, :ref => @ref_stub)
  @s2 = Sensu.create!(:label => @head, :ontology_class => @oc2, :ref => @ref_stub)
  @s3 = Sensu.create!(:label => @flipper, :ontology_class => @oc1, :ref => @ref_stub)
  @s4 = Sensu.create!(:label => @flipper, :ontology_class => @oc2, :ref => @ref_stub)
end

def clear_proj_labels
  Proj.find(1).labels.destroy_all
end

def create_a_basic_linker
  @l = Linker.new(:incoming_text => @text, :proj_id => @proj.id)
end

def create_a_bunch_of_parts
  clear_proj_labels
  Label.create!(:name => "green")
  Label.create!(:name => "flipper")
  Proj.find(1).reload
end

#if description = nil than by default will not retun in Linker; if set to false will return nil descriptions- ks, 07-2009
def create_a_bunch_more_labels_with_definitions
  clear_proj_labels
  l1 = Label.create!(:name => "green") 
  l2 = Label.create!(:name => "flipper") 

  # give ONE of them a definition
  oc1 = OntologyClass.create!(:definition => "Foos in the bar", :written_by => @ref_stub)
  Sensu.create!(:ref => @ref_stub, :ontology_class => oc1, :label => l1)

  Proj.find(1).reload
end

def setup_for_plural_tests
  clear_proj_labels
  @labels = []
    %w(foo bar stuff thing).each_with_index do |w,i|
      @labels[i] = Label.create!(:name => w) # TODO: check this, :description => "FOO!", :is_acronym => false)  
    end

    %w(foo bar stuff thing).each_with_index do |w,i|
      Label.create!(:name => "#{w}s", :plural_of_label => @labels[i]) # TODO: check this, :description => "FOO!", :is_acronym => false)  
    end

    # link the non-plural to defintions
    @labels.each do |l|
      oc = OntologyClass.create!(:definition => "stub for #{l.name}", :written_by => @ref_stub) 
      Sensu.create!(:label => l, :ontology_class => oc, :ref => @ref_stub) 
    end

    @proj.reload
end


end
