require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require File.expand_path(File.dirname(__FILE__) + "/../../lib/ruby_endnote")

class EndnoteTest < ActiveSupport::TestCase
   
  #2 test files available endnote_test.txt, simpleendnote_test.txt
  
  def setup
    @file1 = File.read(File.dirname(__FILE__) + '/../fixtures/test_files/simpleendnote_test.txt')
    @file2 = File.read(File.dirname(__FILE__) + '/../fixtures/test_files/endnote_test.txt')
 
    @file3 =  "%0 Journal Article
              %T Something great happened Here
              %A OhBrother, F.
              %J Journal of Hymenoptera Research
              %V 3
              %P 1-222
              %D 1972"
  end

  def test_that_file3_parses
    @e = RubyEndnote::parse_refs(:txt => @file3)
    assert_equal 1, @e.size
  end

  #assert that test files exist
  def test_endnote_test_file_exists
    assert @file1.size > 0
    assert @file2.size > 0
  end
  
  #assert that text is passed to parse_refs
  def test_parse_refs_txt_returns_array_size_small_file
    @e = RubyEndnote::parse_refs(:txt => @file1)
    assert_equal 5, @e.size
  end
  
  def test_parse_refs_txt_returns_array_size_big_file
    @e = RubyEndnote::parse_refs(:txt => @file2)
    assert_equal 15, @e.size
  end
  
  def test_content_of_array_attributes
    @e = RubyEndnote::parse_refs(:txt => @file1)
    assert_equal "1993", @e[0].year
    assert_equal "1972", @e[1].year
    assert_equal "1988", @e[2].year
    assert_equal ["Brothers, DJ", "Sisters, DJ"], @e[0].authors
    assert_equal "", @e[2].publisher
  end
  
  def test_content_of_array_serial_titles
    @e = RubyEndnote::parse_refs(:txt => @file1)
    assert_equal "Journal of Hymenoptera Research", @e[0].journal_title
    assert_equal "Acarologian", @e[1].journal_title
    assert_equal "Acta Amazonica", @e[2].journal_title
  end

  def test_parse_refs_blank
    @e = RubyEndnote::parse_refs(:txt => "")
    assert_equal false, @e
  end
  
  def test_authors_and_year
    @e = RubyEndnote::parse_refs(:txt => @file1)
    assert_equal "Brothers, DJ, Sisters, DJ, 1993", @e[0].authors_and_year
  end
  
  def test_pretty_journal_citation
    @e = RubyEndnote::parse_refs(:txt => @file1)
    assert_equal "Author, A.(1988). Our stuff. Acta Amazonica. 8:8-88.", @e[2].pretty_journal_citation
  end
  
end
