require 'test/unit'
require 'rubygems'
require 'ruby-debug'

require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/batch_file'))

class BatchFileTest < ActiveSupport::TestCase

  def setup
    @file = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/test_files/batch_file.txt')))
  end

  def test_initialization_without_input_fails
    assert_raise(BatchFile::ParseError) {BatchFile.new()}
  end

  def test_check_headers_false_allows_headers_to_be_read
    @bf = BatchFile.new(:file => @file, :check_headers => false)
    assert_equal [:col1, :col2, :col3], @bf.column_names
  end

  def test_headers_read
    read_file
    assert_equal [:col1, :col2, :col3], @bf.column_names
  end

  def test_row_count
    read_file
    
    assert_equal 5, @bf.row_count
  end

  def test_value_at_row_1_col2
    read_file
    assert_equal "foo", @bf.value_at_row_and_column(1,:col1)
    assert_equal "2", @bf.value_at_row_and_column(4,:col2)
    assert_equal nil, @bf.value_at_row_and_column(2,:col2)
  end

  def test_that_column_col4_is_not_present
    read_file
    assert !@bf.has_column(:col4)
  end

  def test_that_column_col3_is_present
    read_file
    assert @bf.has_column(:col3)
  end

  
  private
  def read_file
    @bf = BatchFile.new(:file => @file, :legal_headers => [:col1, :col2, :col3] )
  end

end
