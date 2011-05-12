# == Schema Information
# Schema version: 20090930163041
#
# Table name: datasets
#
#  id           :integer(4)      not null, primary key
#  parent_id    :integer(4)
#  content_type :string(255)
#  filename     :string(1024)
#  size         :integer(4)
#  proj_id      :integer(4)      not null
#  creator_id   :integer(4)      not null
#  updator_id   :integer(4)      not null
#  updated_on   :timestamp       not null
#  created_on   :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'yaml'

class DatasetTest < ActiveSupport::TestCase

  def setup
    $person_id = 1

    @proj = Proj.create!(:name => 'foo')
    $proj_id = @proj.id

    @file = fixture_file_upload('/test_files/nexus_test.nex', 'text/plain')

    @ds = Dataset.new()
    @ds.uploaded_data = @file  
    @ds.save!
    
    @ref = Ref.create(:title => "foo!")
    @data_source = DataSource.create!(:ref => @ref, :dataset_id => @ds.id, :name => 'foo')
  end
  
  def teardown
    $proj_id = @proj.id # switch back to this project in case we were bad and set $proj_id somewhere
    @ds.destroy # get rid of the file
  end

  def test_new
    assert @ds
    assert_equal 'nexus_test.nex', @ds.display_name
    assert_equal $proj_id, @ds.proj_id
  end

  def test_file_is_not_nexus
    @file = fixture_file_upload('/test_files/nexus_test.nex', 'text/plain')

    not_ds = Dataset.new()
    not_ds.uploaded_data = fixture_file_upload('/test_files/serial_upload_test.txt', 'text/plain')
    not_ds.save!

    print "Ignore this error message: "
    assert_raises NexusParser::ParseError do
      not_ds.nexus_file
    end
    
    not_ds.destroy
  end

  # redundant with plugin, but useful as baseline
  def test_nexus_file
    foo = @ds.nexus_file
    assert_equal NexusParser::NexusParser, foo.class
    
    assert_equal 10, foo.taxa.size
    assert_equal 10, foo.characters.size
    assert_equal 10, foo.codings.size
  end


  def test_convert_nexus_to_db_with_default_options
    options = {}

    assert_equal [[],[],[]], [@proj.otus, @proj.chrs, @proj.codings]

    assert @ds.convert_nexus_to_db(options)

    @proj.reload
    assert_equal 1, @proj.mxes.size
    assert_equal [10,10,77], [ @proj.otus.size,  @proj.chrs.size,  @proj.codings.size]  # - 27, + 4
 
    mx = Mx.find(:first, :conditions => {:proj_id => $proj_id})

    assert_equal 10, mx.chrs.count
    assert_equal 10, mx.otus.size
    assert_equal 77, mx.codings.size

    o0 = Otu.find(:first, :conditions => {:name => 'Dictyna', :proj_id => $proj_id})
    assert_equal 9, o0.codings.size
    assert_equal 10, @proj.otus.size

    o9 = Otu.find(:first, :conditions => {:name => 'Theridiosoma_01', :proj_id => $proj_id})
    assert_equal 0, o9.codings.size

    assert c = Chr.find(:first, :conditions => {:name => 'Median_apophysis', :proj_id => $proj_id})
    assert_equal ["-", "0", "1"], c.states
    assert_equal ["", "abs", "pres"], c.chr_states.collect{|cs| cs.name}.sort
  end

  def test_convert_nexus_to_db_twice_in_a_row_with_same_default_matrix_name_raises
    options = {}
    begin
      assert @ds.convert_nexus_to_db(options)
      @ds.convert_nexus_to_db(options)
    rescue
      assert true
    end
  end

  def test_convert_nexus_to_db_with_bad_ref_id_raises
    options = {:generate_otu_with_ds_ref_id => 95851}
    begin
      @ds.convert_nexus_to_db(options)
    rescue
      assert true
    end
  end


  def test_convert_nexus_to_db_with_generate_tags_from_notes_true
    options = {:generate_tags_from_notes => true}
    assert @ds.convert_nexus_to_db(options)
    @proj.reload

    assert_equal 7, @proj.tags.size # note that commented cells with only "?" do *not* have tags added

    assert tags = Otu.find(:first, :conditions => {:name => "Uloborus", :proj_id => $proj_id}).tags
    assert_equal 1, tags.size
    assert_equal 'This is a footnote to taxon 2, Uloborus', tags[0].notes

    assert tags = Chr.find(:first, :conditions => {:name => "Median_apophysis", :proj_id => $proj_id}).tags 
    assert_equal 1, tags.size
    assert_equal 'This_is_footnote_to_char_10', tags[0].notes

    assert o4 = Otu.find(:first, :conditions => {:name => "Nephila&Herennia", :proj_id => $proj_id}) # otu 9
    assert c8 = Chr.find(:all, :conditions => {:name => "undefined", :proj_id => $proj_id}, :order => :id)[1] # chr 3

    assert c = Coding.find(:all, :conditions => {:otu_id => o4.id, :chr_id => c8.id}) 
    assert c.size > 0
    
    assert_equal 1, c[0].tags.size
    assert_equal 'This_is_a_footnote_to_a_cell.', c[0].tags[0].notes
   
    # CAN'T TAG ? cells!
    
    # assert o9 = Otu.find(:first, :conditions => {:name => "Theridiosoma_01", :proj_id => $proj_id}) # otu 9
    # assert c3 = Chr.find(:first, :conditions => {:name => "Femoral_tuber", :proj_id => $proj_id}) # chr 3

    # assert c = Coding.find(:all, :conditions => {:otu_id => o9.id, :chr_id => c3.id}) 
    # assert c.size > 0
    # assert_equal 1, c[0].tags.size
    # assert_equal 'This is an annotation to chr 3, taxa 9, coded ?', c[0].tags[0].notes
  end



  def test_convert_nexus_to_db_with_generate_tags_from_notes_true_and_generate_tag_with_note
    options = {:generate_tags_from_notes => true, :generate_tag_with_note => "this is a note!"}
    assert @ds.convert_nexus_to_db(options)
    @proj.reload

    assert_equal 7, @proj.tags.size # note that commented cells with only "?" do *not* have tags added

    assert tags = Otu.find(:first, :conditions => {:name => "Uloborus", :proj_id => $proj_id}).tags
    assert_equal 1, tags.size
    assert_equal 'This is a footnote to taxon 2, Uloborus [this is a note!]', tags[0].notes

    assert tags = Chr.find(:first, :conditions => {:name => "Median_apophysis", :proj_id => $proj_id}).tags 
    assert_equal 1, tags.size
    assert_equal 'This_is_footnote_to_char_10 [this is a note!]', tags[0].notes

    assert o4 = Otu.find(:first, :conditions => {:name => "Nephila&Herennia", :proj_id => $proj_id}) # otu 9
    assert c8 = Chr.find(:all, :conditions => {:name => "undefined", :proj_id => $proj_id}, :order => :id)[1] # chr 3

    assert c = Coding.find(:all, :conditions => {:otu_id => o4.id, :chr_id => c8.id}) 
    assert c.size > 0
    
    assert_equal 1, c[0].tags.size
    assert_equal 'This_is_a_footnote_to_a_cell. [this is a note!]', c[0].tags[0].notes
  end



  def test_convert_nexus_to_db_with_generate_short_chr_name_true
    options = {:generate_short_chr_name => true}
    assert @ds.convert_nexus_to_db(options)
    @proj.reload
    
    assert Chr.find(:first, :conditions => {:short_name => 'Tibia_'})
    assert Chr.find(:first, :conditions => {:short_name => 'TII_ma'})
    assert Chr.find(:first, :conditions => {:short_name => 'Femora'})
  end

  def test_convert_nexus_to_db_with_generate_otu_name_with_ds_id_true
    options = {:generate_otu_name_with_ds_id => @data_source.id}
    assert @ds.convert_nexus_to_db(options)
    @proj.reload
    assert Otu.find(:first, :conditions => {:name => "Dictyna [dsid:#{@data_source.id}]"})
    assert Otu.find(:first, :conditions => {:name => "Tetragnatha [dsid:#{@data_source.id}]"})
    assert Otu.find(:first, :conditions => {:name => "Theridiosoma_01 [dsid:#{@data_source.id}]"})
  end


  def test_convert_nexus_to_db_with_generate_chr_name_with_ds_id_true
    options = {:generate_chr_name_with_ds_id => @data_source.id}
    assert @ds.convert_nexus_to_db(options)
    @proj.reload
    
    assert Chr.find(:first, :conditions => {:name => "Tibia_II [dsid:#{@data_source.id}]"})
    assert Chr.find(:first, :conditions => {:name => "Undefined [dsid:#{@data_source.id}]"})
  end
  
  def test_convert_nexus_to_db_generate_chr_with_ds_ref_id_true
    options = {:generate_chr_with_ds_ref_id => @data_source.ref.id}
    assert @ds.convert_nexus_to_db(options)
    @proj.reload
    
    assert Chr.find(:first, :conditions => {:name => "Tibia_II", :cited_in => @data_source.ref.id})
    assert Chr.find(:first, :conditions => {:name => "Undefined", :cited_in => @data_source.ref.id})
  end

 def test_convert_nexus_to_db_generate_otu_with_ds_ref_id_true
    options = {:generate_otu_with_ds_ref_id => @data_source.ref.id}
    assert @ds.convert_nexus_to_db(options)
    @proj.reload
    
    assert Otu.find(:first, :conditions => {:name => "Dictyna", :as_cited_in => @data_source.ref.id})
    assert Otu.find(:first, :conditions => {:name => "Leucauge_venusta", :as_cited_in => @data_source.ref.id})
  end

  def test_convert_nexus_to_db_match_otu_to_db_using_name_true
    assert o = Otu.create(:name => 'Dictyna')

    @proj.reload
    assert_equal 1, @proj.otus.size

    options = {:match_otu_to_db_using_name => true }
    assert @ds.convert_nexus_to_db(options)

    @proj.reload
    o.reload

    assert_equal 10, @proj.otus.size # should not be 11
    assert_equal 9, o.codings.size
  end

  def test_convert_nexus_to_db_match_otu_to_db_using_matrix_name_true
    assert o = Otu.create!(:matrix_name => 'Deinopis')

    @proj.reload
    assert_equal 1, @proj.otus.size

    options = {:match_otu_to_db_using_matrix_name => true }
    assert @ds.convert_nexus_to_db(options)

    @proj.reload
    o.reload

    assert_equal 10, @proj.otus.size # should not be 11
    assert_equal 6, o.codings.size
  end

  def test_convert_nexus_to_db_match_chr_to_db_using_name_true
    assert c = Chr.create!(:name => 'Femoral_tuber')

    c.chr_states << ChrState.new(:state => "0")
    c.chr_states << ChrState.new(:state => "1")
    c.chr_states << ChrState.new(:state => "2")

    @proj.reload
    assert_equal 1, @proj.chrs.size

    options = {:match_chr_to_db_using_name => true }
    assert @ds.convert_nexus_to_db(options)

    @proj.reload
    c.reload

    assert_equal 10, @proj.chrs.size # should not be 11
    assert_equal 9, c.codings.size
  end


end
