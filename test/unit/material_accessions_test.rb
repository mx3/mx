require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class MaterialAccessionsTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars 
    @namespace = Namespace.new(:name => 'Foo', :last_loaded_on =>  5.days.ago.to_date.to_s(:db), :short_name => 'Bar')
    @namespace.save!
  end
  
  def setup_for_imports
   @proj = Proj.find($proj_id)
   @proj.specimens.find(:all).collect{|s| s.destroy}  # wipe all the existing specimens, just in case someone is messing with fixtures
   @proj.lots.find(:all).collect{|s| s.destroy}   
   @proj.reload
   @person =  Person.find($person_id) 

   # we get a namespace from setup
   # create some geogs
   gt = GeogType.create!(:name => 'country')
   Geog.create!(:name => "Canada", :geog_type => gt)

   # mock up a new root
   @bill = TaxonName.new(:name => "Bill", :iczn_group => "genus", :year => '1900')
   @bill.save
   @person.editable_taxon_names << @bill unless @person.editable_taxon_names.include?(@bill)
  
   ProjTaxonName.create!(:proj_id => @proj.id, :taxon_name_id => @bill.id)
   @taxon_name = TaxonName.create_new(:taxon_name => {:name => "Blorf", :iczn_group => "n/a", :parent_id => @bill.id}, :person => Person.find($person_id)) # probably not going to work
   @taxon_name.save 
   @otu = Otu.create!(:name => "Foo", :taxon_name_id => @taxon_name.id)
   @ce = Ce.create!

   @repository = Repository.create!(:coden => "FOO", :name => "Foous")
  end

  def test_that_read_from_batch_raises_with_no_file
    setup_for_imports
    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:proj_id => @proj.id)}
  end

  def test_that_identifiers_do_not_exist_in_database
    setup_for_imports
    s = Specimen.create!()
    Identifier.create!(:namespace_id => @namespace.id, :identifier => '123', :addressable_id => s.id, :addressable_type => 'Specimen')
    
    @file = %w(otu_id identifier).join("\t") + "\n" +
              [@otu.id, "Foo 123"].join("\t")
   
    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  # all specimens have to have an identifier
  def test_that_specimens_have_identifiers
    setup_for_imports
    @file = %w(otu_id identifier).join("\t") + "\n" +
              [@otu.id, "Foo 123"].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 1, @result[:specimens].size

    foo = @result[:identifiers][@result[:specimens][0]]

    assert_equal "Foo 123", "#{foo.namespace.name} #{foo.identifier}" # foo#display_name is not set yet because the record has not been saved
  end

  def test_that_lots_can_have_identifiers
    setup_for_imports
    @file = %w(otu_id identifier count).join("\t") + "\n" +
              [@otu.id, "Foo 345", 20].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 1, @result[:lots].size
    
    foo = @result[:identifiers][@result[:lots][0]]
      
    assert_equal "Foo 345", "#{foo.namespace.name} #{foo.identifier}" # foo#display_name is not set yet because the record has not been saved
  end

  def test_that_specimens_without_an_identifiers_provided_raises
    setup_for_imports
    @file =  %w(otu_id identifier).join("\t") + "\n" +
              [@otu.id, ""].join("\t")
    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end
 
  def test_that_specimen_identifiers_have_valid_namespaces
    setup_for_imports
    @file =  %w(otu_id identifier).join("\t") + "\n" +
              [@otu.id, "SomethingNotInIdentifiers 1232"].join("\t")

    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_adding_with_otu_name_works
    setup_for_imports
    @file =  %w(otu_name identifier).join("\t") + "\n" +
              [ @otu.name, "Foo 123232"].join("\t")
    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 1, @result[:specimens].size
    assert_equal @otu, @result[:specimens][0].specimen_determinations[0].otu
  end

  def test_that_adding_with_otu_name_with_matching_otu_id_works
    setup_for_imports
    @file =  %w(otu_name otu_id identifier).join("\t") + "\n" +
              [ @otu.name, @otu.id, "Foo 123232"].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 1, @result[:specimens].size
    assert_equal @otu, @result[:specimens][0].specimen_determinations[0].otu
  end

  def test_that_adding_non_matching_otu_name_and_otu_id_raises
    setup_for_imports
    @file =  %w(otu_name otu_id identifier).join("\t") + "\n" +
              [ "Nottherightname", @otu.id, "Foo 123232"].join("\t")

    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_adding_by_non_unique_otu_name_raises
    setup_for_imports
    @otu2 = Otu.create!(:name => "Foo") # same name as @otu
    
    @file =  %w(otu_name identifier).join("\t") + "\n" +
              [ "Foo", "Foo 123232"].join("\t")

    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_adding_with_taxon_name_id_works
      setup_for_imports
      @file =  %w(taxon_name_id identifier).join("\t") + "\n" +
                [ @taxon_name.id,  "Foo 123232"].join("\t")
    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
      assert_equal 1, @result[:specimens].size
      assert_equal @otu, @result[:specimens][0].specimen_determinations[0].otu
    end

  def test_that_adding_with_taxon_name_string_works
      setup_for_imports
      @file =  %w(taxon_name_string  identifier).join("\t") + "\n" +
                [ @taxon_name.display_for_list, "Foo 123232"].join("\t") # update #display_for_list to something better
      @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
      assert_equal 1, @result[:specimens].size
      assert_equal @otu, @result[:specimens][0].specimen_determinations[0].otu
    end

  def test_that_adding_with_non_matching_taxon_name_string_and_taxon_name_id_raises
    setup_for_imports
    @file =  %w(taxon_name_string taxon_name_id identifier).join("\t") + "\n" +
              [ "meh", @taxon_name.id, "Foo 123232"].join("\t")

    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file)}
  end

  def test_that_adding_with_matching_taxon_name_string_and_taxon_name_id_works
    setup_for_imports
    @file =  %w(taxon_name_string_name taxon_name_id identifier).join("\t") + "\n" +
              [ @taxon_name.display_for_list, @taxon_name.id, "Foo 123232"].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 1, @result[:specimens].size
    assert_equal @otu, @result[:specimens][0].specimen_determinations[0].otu
  end 

  def test_that_adding_with_non_unique_taxon_name_string_raises
    setup_for_imports
    @taxon_name = TaxonName.create_new(:taxon_name => {:name => "Blorf", :iczn_group => "n/a", :parent_id => @bill.id}, :person => Person.find($person_id)) # probably not going to work
    @file =  %w(taxon_name_string identifier).join("\t") + "\n" +
              [ "Blorf", "Foo 123232"].join("\t")

    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end 

  def test_that_adding_with_taxon_name_id_and_otu_id_even_if_matching_raises
    setup_for_imports
    @file =  %w(taxon_name_id otu_id identifier).join("\t") + "\n" +
              [@taxon_name.id, @otu.id, "Foo 123232"].join("\t")

    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_adding_with_taxon_name_string_and_otu_name_raises
    setup_for_imports
    @file =  %w(taxon_name_string otu_name identifier).join("\t") + "\n" +
              [@taxon_name.display_for_list, @otu.name, "Foo 123232"].join("\t")

    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_adding_with_taxon_name_string_and_otu_id_raises
    setup_for_imports
    @file =  %w(taxon_name_string otu_id identifier).join("\t") + "\n" +
              [@taxon_name.display_for_list, @otu.id, "Foo 123232"].join("\t")
    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_adding_with_taxon_name_id_and_otu_name_raises
    setup_for_imports
    @file =  %w(taxon_name_id otu_name identifier).join("\t") + "\n" +
              [@taxon_name.id, @otu.name, "Foo 123232"].join("\t")
    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  
  def test_that_taxon_name_with_no_match_raises
    setup_for_imports
    @file =  %w(taxon_name_string identifier).join("\t") + "\n" +
              ["Somethingthatcan'tpossiblymatch", @otu.name, "Foo 123232"].join("\t")
    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_otu_name_with_no_match_raises
    setup_for_imports
    @file =  %w(otu_name identifier).join("\t") + "\n" +
              ["Somethingthatcan'tpossiblymatch", "Foo 123232"].join("\t")
    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_otu_id_with_no_match_raises
    setup_for_imports
    @file =  %w(otu_id identifier).join("\t") + "\n" +
              [12312322323, "Foo 123232"].join("\t")
    assert_raise(ActiveRecord::RecordNotFound) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_taxon_name_id_with_no_match_raises
    setup_for_imports
    @file =  %w(taxon_name_id identifier).join("\t") + "\n" +
              [12312322323, "Foo 123232"].join("\t")


    assert_raise(ActiveRecord::RecordNotFound) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_ce_id_with_no_match_raises
    setup_for_imports
    @file =  %w(otu_id ce_id identifier).join("\t") + "\n" +
              [@otu.id, 123123929, "Foo 123232"].join("\t")
    
    assert_raise(ActiveRecord::RecordNotFound) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_otu_id_and_ce_id_and_identifier_adds_specimen
    setup_for_imports

    @file =  %w(ce_id otu_id identifier).join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 123232"].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id, :save => true)

    assert_equal 1, @result[:specimens].size
    assert_equal 1, @result[:specimens][0].specimen_determinations.size
    assert_equal @otu, @result[:specimens][0].specimen_determinations[0].otu
    assert_equal 1, @result[:specimens][0].identifiers.size
    assert_equal "Foo 123232", "#{@result[:specimens][0].identifiers[0].namespace.name} #{@result[:specimens][0].identifiers[0].identifier}"
    assert_equal @ce, @result[:specimens][0].ce 
  end

  def test_that_many_rows_create_many_specimens
    setup_for_imports

    @file =  %w(ce_id otu_id identifier).join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 123" ].join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 124" ].join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 125" ].join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 127" ].join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 128" ].join("\t") 

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 5, @result[:specimens].size
  end

  def test_that_sex_and_stage_are_added_to_specimen
    setup_for_imports

    @file =  %w(ce_id otu_id identifier sex stage).join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 123232", "female", "adult"].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal "adult", @result[:specimens][0].stage
    assert_equal "female", @result[:specimens][0].sex
  end

  def test_that_repository_is_added_by_repository_id
    setup_for_imports

    @file =  %w(ce_id otu_id identifier sex stage repository_id).join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 123232", "female", "adult", @repository.id].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal @repository, @result[:specimens][0].repository
  end

  def test_that_repository_is_added_by_repository_coden
    setup_for_imports

    @file =  %w(ce_id otu_id identifier sex stage repository_coden).join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 123232", "female", "adult", "FOO"].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal @repository, @result[:specimens][0].repository
  end


  def test_that_determinations_by_string_are_added
    setup_for_imports

    @file =  %w(ce_id otu_id identifier det_name det_year det_basis).join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 123232", "Bar", "1023", "Just 'cause"].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 2, @result[:specimens][0].specimen_determinations.size
    assert_equal "Bar", @result[:specimens][0].specimen_determinations[1].name
    assert_equal "1023", @result[:specimens][0].specimen_determinations[1].det_on.year.to_s
    assert_equal "Just 'cause", @result[:specimens][0].specimen_determinations[1].determination_basis
  end


  def test_that_determinations_by_det_otu_id_are_added
    setup_for_imports

    @file =  %w(ce_id otu_id identifier det_otu_id det_year).join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 123232", @otu.id, 1023].join("\t")

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 2, @result[:specimens][0].specimen_determinations.size # one for the otu_id, another for the det
    assert_equal @otu, @result[:specimens][0].specimen_determinations[0].otu


    assert_equal Time.now.year.to_s, @result[:specimens][0].specimen_determinations[0].det_on.year.to_s

    assert_equal "1023", @result[:specimens][0].specimen_determinations[1].det_on.year.to_s
    assert_equal @otu, @result[:specimens][0].specimen_determinations[1].otu
  end


  def test_that_determinations_by_det_otu_id_and_det_name_raises
    setup_for_imports

    @file =  %w(ce_id otu_id identifier det_otu_id det_year det_name).join("\t") + "\n" +
              [@ce.id, @otu.id, "Foo 123232", @otu.id, "1023", "Foo"].join("\t")

    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_providing_verbatim_label_and_ce_id_for_a_specimen_raises
    setup_for_imports

    @file =  %w(ce_id otu_id verbatim_label identifier).join("\t") + "\n" +
              [@ce.id, @otu.id, "Some ce label", "Foo 123"].join("\t")
    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_read_from_batch_makes_a_lot_when_count_is_more_than_one
    setup_for_imports
    @file =  %w(otu_id count).join("\t") + "\n" +
              [@otu.id, 10].join("\t")
    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 1, @result[:lots].size
    assert_equal 10, @result[:lots][0].key_specimens
  end

  def test_that_create_lot_stores_misc_values
    setup_for_imports
    @file =  %w(otu_id count sex stage ce_id repository_id notes).join("\t") + "\n" +
              [@otu.id, 10, "male", "titan", @ce.id, @repository.id, "wheeeee"].join("\t")
    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 1, @result[:lots].size
    assert_equal @repository, @result[:lots][0].repository
    assert_equal @otu, @result[:lots][0].otu
    assert_equal @ce, @result[:lots][0].ce
    assert_equal "male", @result[:lots][0].sex
    assert_equal "titan", @result[:lots][0].stage
    assert_equal "wheeeee", @result[:lots][0].notes
  end

  def test_that_ce_is_created_from_label
    setup_for_imports
    @file =  %w(otu_id verbatim_label identifier ).join("\t") + "\n" +
              [@otu.id, "USA:NC Wake Co. || Some place||Some other line ++ a second label||with a second line", "Foo 123" ].join("\t")
    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal "USA:NC Wake Co.\nSome place\nSome other line\n\na second label\nwith a second line", @result[:specimens][0].ce.verbatim_label
  end

  def test_that_ces_with_identical_verbatim_label_are_not_repeated
    setup_for_imports
    @file =  %w(otu_id identifier verbatim_label  ).join("\t") + "\n" +
            [@otu.id, "Foo 123", "USA:NC Wake Co. || Some place||Some other line ++ a second label||with a second line" ].join("\t") + "\n" +
            [@otu.id, "Foo 345", "USA:NC Snake Co. || Some place||Some other line ++ a second label||with a second line" ].join("\t") + "\n" +
            [@otu.id, "Foo 456", "USA:NC Wake Co.|| Some place||Some other line ++a second label||with a second line" ].join("\t") 

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
      assert @result[:specimens][0].ce == @result[:specimens][2].ce
      assert @result[:specimens][0].ce != @result[:specimens][1].ce
  end

  def test_that_ces_with_existing_md5s_are_used
    setup_for_imports
    @ce = Ce.new(:verbatim_label => "USA:NC Wake Co.\nSome place\nSome other line\n\na second label\nwith a second line")
    @ce.save!
    
    assert !@ce.verbatim_label_md5.nil?

    @file =  %w(otu_id identifier verbatim_label  ).join("\t") + "\n" +
            [@otu.id, "Foo 123", "USA:NC Wake Co. || Some place||Some other line ++ a second label||with a second line" ].join("\t") + "\n" +
            [@otu.id, "Foo 345", "USA:NC Snake Co. || Some place||Some other line ++ a second label||with a second line" ].join("\t") + "\n" +
            [@otu.id, "Foo 456", "USA:NC Wake Co.|| Some place||Some other line ++a second label||with a second line" ].join("\t") 

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id, :save => true)
    assert_equal @ce, @result[:specimens][0].ce
  end

  def test_that_ces_with_existing_md5s_are_used_and_fields_match
    setup_for_imports
    @ce = Ce.new(:verbatim_label => "USA:NC Wake Co.\nSome place\nSome other line\n\na second label\nwith a second line", :latitude => '23.23', :longitude => '44.52')
    @ce.save!
    
    assert !@ce.verbatim_label_md5.nil?

    @file =  %w(otu_id identifier verbatim_label  ).join("\t") + "\n" +
            [@otu.id, "Foo 123", "USA:NC Wake Co. || Some place||Some other line ++ a second label||with a second line" ].join("\t") + "\n" +
            [@otu.id, "Foo 345", "USA:NC Snake Co. || Some place||Some other line ++ a second label||with a second line" ].join("\t") + "\n" +
            [@otu.id, "Foo 456", "USA:NC Wake Co.|| Some place||Some other line ++a second label||with a second line" ].join("\t") 
    
    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id, :save => true)}
  end

  def test_that_duplicate_identifiers_are_not_allowed
    setup_for_imports
    @file =  %w(ce_id otu_id identifier).join("\t") + "\n" +
              [@ce.id, @otu.id, "FOO 123232"].join("\t") + "\n" +
              [@ce.id, @otu.id, "FOO 123232"].join("\t")

    assert_raise(MaterialAccessions::BatchParseError) {MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)}
  end

  def test_that_type_status_is_created_when_included
    setup_for_imports

    @file =  %w(ce_id otu_id identifier type type_of_taxon_name_id).join("\t") + "\n" +
              [@ce.id, @otu.id, "FOO 123232", "holotype", @taxon_name.id].join("\t") 
     
    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
    assert_equal 1, @result[:specimens][0].type_specimens.size
    assert_equal "holotype", @result[:specimens][0].type_specimens[0].type_type
  end

  def test_that_specimen_creator_is_set_to_data_capturer
    setup_for_imports

    @file =  %w(ce_id otu_id data_entry_by identifier).join("\t") + "\n" +
              [@ce.id, @otu.id, "krishna", "Foo 123"].join("\t") 
     
    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id)
 
    assert_equal 1, @result[:specimens][0].creator_id
    assert_equal 1, @result[:specimens][0].updator_id
  end

end
