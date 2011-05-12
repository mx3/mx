require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class SeqTest < ActiveSupport::TestCase
  fixtures :people, :people_projs, :projs
  self.use_instantiated_fixtures  = true
  
  def setup
    set_before_filter_vars
    @gene = Gene.new(:name => "Foo")
    @gene.save!
    @otu = Otu.create!(:name => "Foo")
    @primer1 = Primer.create!(:name => "A", :sequence => "ACG")
    @primer2 = Primer.create!(:name => "b", :sequence => "ACT")

    @specimen = Specimen.create!()
    @extract = Extract.create!(:specimen => @specimen)

    @pcr = Pcr.create!(:fwd_primer => @primer1, :rev_primer => @primer2, :extract => @extract)
  end

  def test_that_all_three_of_gene_id_pcr_id_and_otu_id_are_not_present
    @seq = Seq.new(:pcr => @pcr, :otu => @otu, :gene => @gene)
    assert !@seq.save
    assert !@seq.valid?
  end

  def test_that_seq_with_gene_id_must_have_otu_id
    @seq = Seq.new(:otu => @otu)
    assert !@seq.valid?
    @seq2 = Seq.new(:gene => @gene)
    assert !@seq2.valid?
  end

  def test_that_seq_with_pcr_id_must_not_have_gene_id
    @seq = Seq.new(:pcr => @pcr, :gene => @gene)
    assert !@seq.valid?   
  end

  def test_that_seq_with_pcr_id_must_not_have_otu_id
    @seq = Seq.new(:pcr => @pcr, :otu => @otu)
    assert !@seq.valid?   
  end

  def test_that_pcr_id_and_sequence_id_are_not_combined
    @seq = Seq.new(:pcr => @pcr, :otu => @otu)
    assert !@seq.valid?   
  end

  # why?! NO LONGER HOLDS
 #def test_that_only_one_instance_of_gene_id_and_otu_id_exist
 #  @seq = Seq.new(:gene => @gene, :otu => @otu)
 #  @seq.save!

 #  @seq2 = Seq.new(:gene => @gene, :otu => @otu)
 #  assert !@seq.valid?
 #end

  def _setup_pcrs_and_seq_file_for_batch_tests
   @proj = Proj.find($proj_id) 
   
   @proj.pcrs.destroy_all

    (0..4).each do |i|
      Pcr.create!(:fwd_primer => @primer1, :rev_primer => @primer2, :extract => @extract)
    end

    @proj.reload

    foo = File.new((File.dirname(__FILE__) + '/../fixtures/test_files/seqs.fasta'), "w+")
    foo.puts @proj.pcrs.collect{|p| ">seq_#{p.id}\nACGTCGT"}.join("\n\n")
    foo.close

    @fasta_file = File.open((File.dirname(__FILE__) + '/../fixtures/test_files/seqs.fasta'), "r") 
  end

  def test_fasta_file_matching_pcr_ids
    _setup_pcrs_and_seq_file_for_batch_tests
    assert foo = Seq.batch_load_FASTA(:file => @fasta_file)
    assert_equal 5, foo.size    
  end

end

