require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class PcrTest < ActiveSupport::TestCase
  
  def setup
    set_before_filter_vars
    @gene1 = Gene.create!(:name => "Foo")
    @gene2 = Gene.create!(:name => "Bar")
    
    @primer1 = Primer.create!(:name => "A", :sequence => "ACG", :gene => @gene1)
    @primer2 = Primer.create!(:name => "B", :sequence => "ACT", :gene => @gene1)
    @primer3 = Primer.create!(:name => "C", :sequence => "ACC", :gene => @gene2)

    @specimen = Specimen.create!()
    @extract = Extract.create!(:specimen => @specimen)

  end

  def test_has_many_genes
    @pcr1 = Pcr.create!(:fwd_primer => @primer1, :rev_primer => @primer2, :extract => @extract)
    assert_equal [@gene1], @pcr1.genes 

    @pcr2 = Pcr.create!(:fwd_primer => @primer1, :rev_primer => @primer3, :extract => @extract)
    assert_equal [@gene1, @gene2], @pcr2.genes 
  end 

  def test_with_sequence_nucleotides
    @pcr1 = Pcr.create!(:fwd_primer => @primer1, :rev_primer => @primer2, :extract => @extract)
    @pcr2 = Pcr.create!(:fwd_primer => @primer1, :rev_primer => @primer3, :extract => @extract)
    @proj = Proj.find($proj_id)    
   
    @seq1 = Seq.create!(:pcr => @pcr1, :sequence => nil) 
    @seq2 = Seq.create!(:pcr => @pcr2, :sequence => 'ACTGT') 

    assert_equal [@pcr2], @proj.pcrs.with_sequence_nucleotides
  end

end

