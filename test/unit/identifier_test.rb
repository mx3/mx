require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class IdentifierTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars
    @object = Specimen.create!
   
    @namespace = Namespace.new(:name => 'Foo', :last_loaded_on =>  5.days.ago.to_date.to_s(:db), :short_name => 'Bar' )
    @namespace.save!
  end

  def create_a_base_identifier
    @i = Identifier.new(:addressable_type => @object.class.to_s, :addressable_id => @object.id)
  end

  test "that an empty identifier is not valid" do
    create_a_base_identifier
    
    assert !@i.valid?
    assert @i.errors.on(:identifier) 
  end

  test "that an identifier with both identifier and global_identifier is invalid" do
    create_a_base_identifier
    @i.identifier = '1234'
    @i.global_identifier = 'http://123.456.789/foo/1'

    assert !@i.valid?
    assert @i.errors.on(:identifier) 
    assert @i.errors.on(:global_identifier) 
    assert @i.errors.on(:global_identifier_type) 
  end

  test "that an identifier with namespace and identifier is valid" do 
    create_a_base_identifier
    @i.identifier = '1235'
    @i.namespace = @namespace
    assert @i.valid?
  end

  test "that an identifier with global_identifier and without global_identifier_type is invalid" do
    create_a_base_identifier
    @i.global_identifier = 'http://123.456.789/foo/1'
    assert !@i.valid?
    assert @i.errors.on(:global_identifier_type) 

  end

  test "that an identifier with global_identifier and with a invalid global_identifier_type is invalid" do
    create_a_base_identifier
    @i.global_identifier = 'http://123.456.789/foo/1'
    @i.global_identifier_type = 'some rediculous type that can never be real'
    assert !@i.valid?
    assert @i.errors.on(:global_identifier_type) 
  end

  test "that an identifier with global_identifier and with a valid global_identifier_type is valid" do
    create_a_base_identifier
    @i.global_identifier = 'FOO:1234'
    @i.global_identifier_type = 'xref'
    assert @i.valid?
  end

  test "that improperly formatted xref global_identifiers are invalid" do
    create_a_base_identifier
    @i.global_identifier = 'FOO1234'
    @i.global_identifier_type = 'xref'
    assert !@i.valid?
    assert @i.errors.on(:global_identifier) 
  end

  test "that properly formatted xref global_identifiers are valid" do
    create_a_base_identifier
    @i.global_identifier = 'FOO:1234'
    @i.global_identifier_type = 'xref'
    assert @i.valid?
  end

  test "that an identical identifiers can not be used for both lots and specimens" do
    create_a_base_identifier
    @i.identifier = '1234'
    @i.namespace = @namespace
    assert @i.valid?
 
    o = Otu.create!(:name => 'O') 
    lot = Lot.create!(:value_specimens => 2, :otu_id => o.id)
    i2 = Identifier.new(:addressable_type => @lot.class.to_s, :addressable_id => lot.id, :identifier => '1234', :namespace => @namespace)
    i2.save!
   
    assert !@i.valid?
    assert @i.errors.on(:identifier)
  end

  test "that an identfier has a cached_display_name composed of namespace short name" do
    create_a_base_identifier
    @i.identifier = '1234'
    @i.namespace = @namespace
    assert @i.save
    assert_equal 'Bar 1234', @i.cached_display_name
  end

  test "that updating a namespace updates the cached_display_name of tied identifiers" do
    create_a_base_identifier
    @i.identifier = '1234'
    @i.namespace = @namespace
    assert @i.save
    @namespace.reload
    assert_equal 'Bar 1234', @i.cached_display_name
    @namespace.short_name = "Blorf"
    assert @namespace.save!
    assert_equal 'Blorf 1234', Identifier.find(@i.id).cached_display_name
  end



end
