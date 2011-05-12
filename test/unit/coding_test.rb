require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class CodingTest < ActiveSupport::TestCase

  def setup
   set_before_filter_vars
   @chr = Chr.create!(:name => "Foo")
   @chr.chr_states << ChrState.new(:state => "a")
   @chr.chr_states << ChrState.new(:state => "b")
   @chr.save
   @chr.reload
   @otu = Otu.create!(:name => "Bar") 
  end

  test "that otu is required" do 
    c = Coding.new(:otu => nil, :chr => @chr, :chr_state => @chr.chr_states.first)
    assert !c.valid?
  end

  test "that chr is required" do
    c = Coding.new(:chr => nil, :otu => @otu, :chr_state => @chr.chr_states.first)
    assert !c.valid?
  end

  test "that codings can not have both of continuous_state and chr_state_id" do
    c = Coding.new(:chr => @chr, :otu => @otu, :chr_state => @chr.chr_states.first, :continuous_state => 20)
    assert !c.valid?
  end

  test "that continuous_state without chr_state_id is legal" do
    c = Coding.new(:chr => @chr, :otu => @otu,  :continuous_state => 20)
    assert c.save
    assert c.valid?
  end

  test "that chr_state_id without continuous_state is legal" do
    c = Coding.new(:chr => @chr, :otu => @otu, :chr_state => @chr.chr_states.first)
    assert c.save
    assert c.valid?
  end




end
