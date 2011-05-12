require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class CeTest < ActiveSupport::TestCase

  # several of the tests here are mashups of OntologyClass and OntologyRelationship, if in doubt place place/leave these here
  def setup
    set_before_filter_vars
    @proj = Proj.find($proj_id) 
  end

  test "that start_date variously converts roman to arabic" do
    ce = Ce.create!(:sd_d => '23', :sd_m => 'ix', :sd_y => 'MMX')
    assert_equal '23.9.2010', ce.start_date

    ce = Ce.create!(:sd_d => '23', :sd_m => '9', :sd_y => '1999')
    assert_equal '23.9.1999', ce.start_date

    ce = Ce.create!(:sd_d => nil, :sd_m => 'viii', :sd_y => '1999')
    assert_equal '8.1999', ce.start_date
  end

  test "that end_date variously converts roman to arabic" do
    ce = Ce.create!(:sd_d => '23', :sd_m => 'ix', :sd_y => 'MMX', :ed_d => '2', :ed_m => 'ix', :ed_y => 'MMX')
    assert_equal '2.9.2010', ce.end_date
  end

  test "that empty end_date returns empty string" do
    ce = Ce.create!(:sd_d => '23', :sd_m => 'ix', :sd_y => 'MMX')
    assert_equal '', ce.end_date
  end

  test 'that start_day_of_year works from roman or integer' do
    ce = Ce.create!(:sd_d => '1', :sd_m => 'i', :sd_y => 'MMX')
    assert_equal 1, ce.start_day_of_year

    ce = Ce.create!(:sd_d => '5', :sd_m => '2', :sd_y => 'MMX')
    assert_equal 36, ce.start_day_of_year
  end

  test 'that date_range for ces with start is formatted properly' do
    ce = Ce.create!(:sd_d => '1', :sd_m => 'i', :sd_y => 'MMX')
    assert_equal '1.1.2010', ce.date_range 
  end 

  test 'that date_range for ces with start and end date within same month is formatted properly' do
    ce = Ce.create!(:sd_d => '1', :sd_m => 'i', :sd_y => 'MMX', :ed_d => '10', :ed_m => '1', :ed_y => '2010')
    assert_equal '1-10.1.2010', ce.date_range 
  end 

  test 'that date_range for ces with month range and same year is formatted properly' do
    ce = Ce.create!(:sd_d => '5', :sd_m => 'i', :sd_y => 'MMX', :ed_d => '7', :ed_m => '2', :ed_y => '2010')
    assert_equal '5.1-7.2.2010', ce.date_range 
  end 

  test 'that date_range with start year only is formatted properly' do
    ce = Ce.create!(:sd_y => '1999')
    assert_equal '1999', ce.date_range 
  end

  test 'that date_range with month range and year only is properly formatted' do
    ce = Ce.create!(:sd_m => '2', :sd_y => '1999', :ed_m => '3')
    assert_equal '2-3.1999', ce.date_range 
  end

   test 'that date_range with year range only is properly formatted' do
    ce = Ce.create!(:sd_y => '1999', :ed_y => '2000')
    assert_equal '1999-2000', ce.date_range 
  end





  test "that ces generate md5 profiles of verbatim labels" do
    @ce = Ce.new(:verbatim_label => 'This is a foo')
    assert_equal nil, @ce.verbatim_label_md5
    @ce.save
    assert !@ce.verbatim_label_md5.nil?
  end

  test 'that ces with no verbatim label do not throw warnings'  do
    @ce = Ce.new(:verbatim_label => nil)
    assert @ce.save!
  end

  test 'that ces with identical verbatim labels can not be created' do
    @ce = Ce.new(:verbatim_label => 'foo')
    assert @ce.save
    @ce2 = Ce.new(:verbatim_label => 'foo')
    assert !@ce2.save
  end

  test 'that ces can be updated after save' do
    @ce = Ce.new(:verbatim_label => 'foo')
    assert @ce.save 
    @ce.locality = "Something new!"
    assert @ce.save
  end

  test 'that verbatim label can be updated after save' do
    @ce = Ce.new(:verbatim_label => 'foo')
    assert @ce.save 
    @ce.verbatim_label = "bar"
    assert @ce.save
  end

  test 'that multiple ces with blank verbatim labels can be created' do
    @ce = Ce.new(:locality => 'foo')
    assert @ce.save 
    @ce2 = Ce.new(:locality => 'bar')
    assert @ce2.save
  end


  test 'that identical verbatim_labels across projects are allowed' do
    proj = Proj.create!(:name => 'foo')
    @ce = Ce.new(:verbatim_label => 'foo')
    assert @ce.save 
    $proj_id = proj.id 
    @ce2 = Ce.new(:verbatim_label => 'foo')
    assert @ce2.save
  end

  test "that you can update all md5s" do
    assert Ce.regenerate_all_md5s
  end

  test "that ces from text are extracted just so" do
    txt = "OneLabel\n\nSecond||Label\n\nThird||Label\nThird Line\n\nForth Label++Second Line\n"

    ces = Ce.from_text(txt)
    assert_equal 4, ces.size
    assert_equal "OneLabel\n", ces[0]
    assert_equal "Second\nLabel\n", ces[1]
    assert_equal "Third\nLabel\nThird Line\n", ces[2]
    assert_equal "Forth Label\n\nSecond Line\n", ces[3]
  end

end
