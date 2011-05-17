
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class SpecimenTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars
    @namespace = Namespace.new(:name => 'Foo', :last_loaded_on =>  5.days.ago.to_date.to_s(:db), :short_name => 'Bar' )
    @namespace.save!
  end
  
  def test_new
    @s = Specimen.new()
    assert @s.save!
  end

  def test_add_determination
    assert @o = Otu.create(:name => 'foo')
    
    @s1 = Specimen.new
    @s1.save!
    @i1 = SpecimenDetermination.new()
    assert_raise(ActiveRecord::RecordInvalid) { @s1.specimen_determinations << @i1 }  
    @i1.otu = @o
    
    assert @s1.specimen_determinations << @i1
  end
 
  def create_some_determined_specimens
    @s1 = Specimen.create!
    @s2 = Specimen.create!
    @s3 = Specimen.create!

    @o1 = Otu.create!(:name => 'foo')
    @o2 = Otu.create!(:name => 'bar')

    @s1.specimen_determinations << SpecimenDetermination.new(:otu => @o1, :det_on => Date.new('2007'.to_i)) 
    @s1.specimen_determinations << SpecimenDetermination.new(:otu => @o2, :det_on => Date.new('1928'.to_i)) 

    @s2.specimen_determinations << SpecimenDetermination.new(:otu => @o1, :det_on => Date.new('1928'.to_i)) 
    @s2.specimen_determinations << SpecimenDetermination.new(:otu => @o2)  

    @s3.specimen_determinations << SpecimenDetermination.new(:otu => @o1)
    sleep(1) # ensure the next record gets created slightly later
    @s3.specimen_determinations << SpecimenDetermination.new(:otu => @o2) 

    [@s1, @s2, @s3].each do |s|
      s.reload
    end
  end

  def test_most_recent_determination
    create_some_determined_specimens 
    assert_equal @o1, @s1.most_recent_determination.otu

    assert_equal @o2, @s2.most_recent_determination.otu

    assert_equal @o2, @s3.most_recent_determination.otu
  end

  def test_named_scope_with_current_determination
    create_some_determined_specimens
    assert_equal [@s1], @o1.specimens_most_recently_determined_as
    assert_equal [@s2, @s3], @o2.specimens_most_recently_determined_as
  end

  def test_mappable
    ce = Ce.create!(:latitude => 0.1232 , :longitude => 45.232)
    s = Specimen.create!(:ce => ce)
    
    assert s.mappable

    s2 = Specimen.create!()
    assert !s2.mappable
  end

  test 'that specimens with no determinations can be cloned with make_clone' do 
    s = Specimen.create!
    assert_equal Specimen, s.make_clone.class
  end

  test 'that clones specimens retain determinations with make_clone' do
    assert @o = Otu.create(:name => 'foo')
    assert s = Specimen.create!
    s.specimen_determinations << SpecimenDetermination.new(:otu => @o)
    s.save

    bar = s.make_clone
    bar.reload
    assert_equal @o, bar.specimen_determinations.first.otu
  end

end

