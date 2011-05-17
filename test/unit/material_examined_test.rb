require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require File.expand_path(File.dirname(__FILE__) + "/../../lib/material_examined")

class MaterialExaminedTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars
    @person =  Person.find($person_id) 
    @proj = Proj.find($proj_id) 

    %w(Foo Bar Goo).each do |w|
      @namespace = Namespace.new(:name => w, :last_loaded_on =>  5.days.ago.to_date.to_s(:db), :short_name => w )
      @namespace.save!
    end

    @country = GeogType.create!(:name => "Country")
    @state = GeogType.create!(:name => "State")
    @county = GeogType.create!(:name => "County")
    @g1 = Geog.create!(:geog_type => @country, :name => "Canada")
    @g2 = Geog.create!(:geog_type => @country, :name => "USA")
    @g3 = Geog.create!(:geog_type => @country, :name => "Mexico")
    @g4 = Geog.create!(:geog_type => @state, :country => @g2, :name => "Texas")
    @g5 = Geog.create!(:geog_type => @county, :country => @g2, :state => @g4, :name => "Hidalgo")

    @g1.update_attributes!(:country => @g1)
    @g2.update_attributes!(:country => @g2)
    @g3.update_attributes!(:country => @g3)
    @g4.update_attributes!(:country => @g2)
    @g4.update_attributes!(:country => @g2)

    @o = Otu.create!(:name => "foo")

    @ce1 = Ce.create!(:geog => @g1)
    @ce2 = Ce.create!(:geog => @g2)
    @ce3 = Ce.create!(:geog => @g3)
    @ce4 = Ce.create!(:geog => @g4)
    @ce5 = Ce.create!(:geog => @g5)

   @bill = TaxonName.new(:name => "Bill", :iczn_group => "genus", :year => '1900')
   @bill.save
   @person.editable_taxon_names << @bill unless @person.editable_taxon_names.include?(@bill)
  
   ProjTaxonName.create!(:proj_id => @proj.id, :taxon_name_id => @bill.id)
   @taxon_name = TaxonName.create_new(:taxon_name => {:name => "florf", :iczn_group => "species", :parent_id => @bill.id}, :person => Person.find($person_id)) # probably not going to work
   @taxon_name.save 

   @o.taxon_name = @taxon_name
   @o.save

   @repository = Repository.create!(:coden => "FOO", :name => "Foous")

   @proj.reload

   # use the batch importer to create some specimens!
   @file =  %w(ce_id otu_id identifier sex stage repository_coden type_of_taxon_name_id type).join("\t") + "\n" +
              [@ce1.id, @o.id, "Foo 0", "male",   "adult", "FOO", @taxon_name.id, "holotype"].join("\t") + "\n" +
              [@ce2.id, @o.id, "Foo 1", "female", "adult", "FOO", @taxon_name.id, "paratype"].join("\t") + "\n" +
              [@ce3.id, @o.id, "Foo 2", "male",   "adult", "FOO", @taxon_name.id, "paratype"].join("\t") + "\n" +
              [@ce4.id, @o.id, "Foo 3", "female", "adult", "FOO", @taxon_name.id, "paratype"].join("\t") + "\n" +
              [@ce5.id, @o.id, "Foo 4", "male",   "adult", "FOO", @taxon_name.id, "paratype"].join("\t") + "\n" +
              [@ce1.id, @o.id, "Foo 5", "female", "adult", "FOO", @taxon_name.id, "paratype"].join("\t") + "\n" +
              [@ce2.id, @o.id, "Goo A", "female", "adult", "FOO", @taxon_name.id, "paratype"].join("\t") + "\n" +
              [@ce3.id, @o.id, "Bar 7", "female", "adult", "FOO", "",             ""        ].join("\t") + "\n" +
              [@ce4.id, @o.id, "Bar 8", "female", "adult", "FOO", "",             ""        ].join("\t") + "\n" +
              [@ce5.id, @o.id, "Bar 9", "female", "adult", "FOO", "",             ""        ].join("\t") 

    @result = MaterialAccessions.read_from_batch(:file => @file, :proj_id => @proj.id, :save => true)

    @me = MaterialExamined.new(:otu_id => @o.id)
  end

  def test_that_setup_worked
     assert_equal 10, @result[:specimens].size
  end

  def test_id_str
    assert_equal "Bar 7-9; Foo 0-5; Goo A", @me.id_str(@result[:specimens])
  end

  def test_inst_str
    assert_equal "Bar 7-9; Foo 0-5; Goo A (FOO)", @me.inst_str(@result[:specimens])
  end

  def test_sex_str
    assert_equal "7 females, 3 males", @me.sex_str(@result[:specimens])
  end

  def test_country_str
    assert_equal "CANADA: 1 female, 1 male. Foo 0, 5 (FOO). MEXICO: 1 female, 1 male. Bar 7; Foo 2 (FOO). USA: 5 females, 1 male. Bar 8-9; Foo 1, 3-4; Goo A (FOO).", @me.country_str(@result[:specimens])
  end

  def test_full_me_for_specimens
     assert_equal  "Holotype male: CANADA: Foo 0 (deposited in FOO). Paratypes (4 females, 2 males): CANADA: 1 female. Foo 5 (FOO). MEXICO: 1 male. Foo 2 (FOO). USA: 3 females, 1 male. Foo 1, 3-4; Goo A (FOO). Other material (3 females): MEXICO: 1 female. Bar 7 (FOO). USA: 2 females. Bar 8-9 (FOO).", @me.full_me_for_specimens
  end
  
end

