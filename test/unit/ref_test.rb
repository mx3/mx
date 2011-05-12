# == Schema Information
# Schema version: 20090930163041
#
# Table name: refs
#
#  id             :integer(4)      not null, primary key
#  namespace_id   :integer(4)
#  external_id    :integer(4)
#  serial_id      :integer(4)
#  valid_ref_id   :integer(4)
#  language_id    :integer(4)
#  pdf_id         :integer(4)
#  year           :integer(2)
#  year_letter    :string(255)
#  ref_type       :string(50)
#  title          :text
#  volume         :string(255)
#  issue          :string(255)
#  pages          :string(255)
#  pg_start       :string(8)
#  pg_end         :string(8)
#  book_title     :text
#  city           :string(255)
#  publisher      :string(255)
#  institution    :string(255)
#  date           :string(255)
#  language_OLD   :string(255)
#  notes          :text
#  ISBN           :string(14)
#  DOI            :string(255)
#  is_public      :boolean(1)
#  pub_med_url    :text
#  other_url      :text
#  full_citation  :text
#  temp_citation  :text
#  display_name   :string(2047)
#  short_citation :string(255)
#  author         :string(255)
#  journal        :string(255)
#  creator_id     :integer(4)      not null
#  updator_id     :integer(4)      not null
#  updated_on     :timestamp       not null
#  created_on     :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class RefTest < ActiveSupport::TestCase
  
  fixtures :refs, :serials, :authors, :people, :taxon_names, :people_taxon_names
  
  def setup
    set_before_filter_vars
  end
  
  def create_a_pile_of_refs_n_stuff
    $person_id = 1

    # work within first project
    $proj_id = 1
    refs = [refs(:ref1), refs(:ref3)]
    Proj.find(1).refs = refs
    r = refs[0]
   
    @my_tn = TaxonName.create_new(:taxon_name => {:ref_id => r.id, :name => "test", :iczn_group => "species", :parent_id => 1},  :person => Person.find($person_id)     )
 
    # now strip person 1's ability to alter @my_tn
    person = Person.find($person_id) 
    
    person.editable_taxon_names.each do |n|
      person.editable_taxon_names.delete(n)
    end

    @my_otu = Otu.create!(:as_cited_in => r.id, :name => "foo")
    kw = Keyword.create!(:keyword => "foo")
    @my_tag = Tag.create!(:ref_id => r.id, :addressable_type => "Otu", :addressable_id => @my_otu.id, :keyword_id => kw.id)
    s = "'#{r.id}'"
    
    ct = ContentType.create!(:name => "foo")
    otu = Otu.create!(:name => 'bar')
    @my_content = Content.create!(:text => "Hi <ref id=#{s}>2007</ref> ho <ref id='12345'>Bar 2006</ref> fum<ref id='#{r.id}'> Foo</ref>.", :content_type => ct, :otu => otu)
   
    # work within a second project 
    $proj_id = 8
    refs = [refs(:ref2), refs(:ref3)]
    Proj.find(8).refs = refs
    r = refs[1]
    @other_otu = Otu.create!(:as_cited_in => r.id, :name => "foo")
    kw = Keyword.create!(:keyword => "foo") 
    @other_tag = Tag.create!(:ref_id => r.id, :addressable_type => "Otu", :addressable_id => @other_otu.id, :keyword_id => kw.id)
    @other_content = Content.create!(:text => "Hi <ref id='#{r.id}'>2007</ref> ho <ref id='12345'>Bar 2006</ref> fum<ref id='#{r.id}'> Foo</ref>.", :content_type => ct, :otu => otu)
  end
  
  
  def test_merge
    create_a_pile_of_refs_n_stuff
    
    # non-shared refs get deleted
    $proj_id = 1
    ref = refs(:ref1)
    
    ref.delete_or_replace_with(refs(:ref3))
    assert_equal [refs(:ref3)], Proj.find($proj_id).refs # replaced :ref1 with ref3 # ... removed from project

    # below is important, see caporns
    assert_equal ref.id, @my_tn.ref_id # user can't change taxon name
    assert Ref.find(ref.id) # not deleted because of taxon_name
   	
	  Person.find($person_id).editable_taxon_names = TaxonName.find(:all)

    ref = refs(:ref1)
    Proj.find($proj_id).refs << ref
    ref.delete_or_replace_with(refs(:ref3))
    assert_equal nil, Ref.find_by_id(ref.id) # deleted now that user can edit taxon name
    # all has_manys get merged to new ref
    assert_equal refs(:ref3).id, @my_tn.reload.ref_id # taxon_names get updated if owned
    assert_equal refs(:ref3).id, @my_otu.reload.as_cited_in
    assert_equal refs(:ref3).id, @my_tag.reload.ref_id
    # links in content get set to new id, but only for this ref in this project
    assert_equal "Hi <ref id=\"#{refs(:ref3).id}\">2007</ref> ho <ref id=\"12345\">Bar 2006</ref> fum<ref id=\"#{refs(:ref3).id}\"> Foo</ref>.", 
              @my_content.reload.text
    
    # ref3 is a shared ref
    ref = refs(:ref2)
    Proj.find($proj_id).refs << ref    
    refs(:ref3).delete_or_replace_with(ref)
    # shared refs get merged in current project only, and not deleted
    assert_equal [ref], Proj.find($proj_id).refs
    assert Ref.find_by_id(refs(:ref3).id)
    # other proj objects not affected
    assert_equal refs(:ref3).id, @other_otu.reload.as_cited_in
    assert_equal refs(:ref3).id, @other_tag.reload.ref_id
    assert_equal "Hi <ref id=\"#{refs(:ref3).id}\">2007</ref> ho <ref id=\"12345\">Bar 2006</ref> fum<ref id=\"#{refs(:ref3).id}\"> Foo</ref>.", 
              @other_content.reload.text
    # valid_ref_id gets set
    assert_equal ref.id, refs(:ref3).valid_ref_id
  end
  
  
  def test_delete
    create_a_pile_of_refs_n_stuff
        
    # non-shared refs get deleted
    $proj_id = 1
 	  $person_id = 2 # this person can't delete/update @my_tn --- which should throw an error? 
  	ref = refs(:ref1)
    ref.delete_or_replace_with()
    assert_equal [refs(:ref3)], Proj.find($proj_id).refs # removed from project
 
	  assert_equal ref.id, @my_tn.ref_id # user can't change taxon name
	  assert Ref.find(ref.id) # not deleted because of taxon_name
  
   	Person.find($person_id).editable_taxon_names = TaxonName.find(:all)
	  
    ref = refs(:ref1)
    Proj.find($proj_id).refs << ref
    ref.delete_or_replace_with()
    assert_equal nil, Ref.find_by_id(ref.id) # deleted now that user can edit taxon name
    # has_manys that are :nullify get set to null, but only in the current project
    assert_equal nil, @my_tn.reload.ref_id # taxon_names get updated if owned
    assert_equal nil, @my_otu.reload.as_cited_in
    # has_manys that are :destroy get nuked, but only in the current project
    assert_equal nil, Tag.find_by_id(@my_tag.id)
    # links in content get set to '', but only for this ref in this project
    assert_equal "Hi <ref id=\"\">2007</ref> ho <ref id=\"12345\">Bar 2006</ref> fum<ref id=\"\"> Foo</ref>.", 
    @my_content.reload.text
    
    # ref3 is a shared ref
    refs(:ref3).delete_or_replace_with()
    # shared refs get merged in current project only, and not deleted
    assert_equal [], Proj.find($proj_id).refs
    assert Ref.find_by_id(refs(:ref3).id)
    # other proj objects not affected
    assert_equal refs(:ref3).id, @other_otu.reload.as_cited_in
    assert_equal refs(:ref3).id, @other_tag.reload.ref_id
    assert_equal "Hi <ref id=\"#{refs(:ref3).id}\">2007</ref> ho <ref id=\"12345\">Bar 2006</ref> fum<ref id=\"#{refs(:ref3).id}\"> Foo</ref>.", 
    @other_content.reload.text
  end
  
  def test_notify_on_update
    # TODO: ensure sent to all members of other projects using this ref - current user
  end
  
  def test_notify_taxon_names
    # TODO: notification is sent if taxon name can't be updated
  end
  
  # rendering tests, see also auths_test.rb
  def test_single_auth
   ref = refs(:ref_rendering_test_1)
   assert_equal 'Blorf, F.-B. B. B.', ref.authors_for_display
   assert_equal 'Blorf, F.-B. B. B. 1918.', ref.authors_year
   assert_equal 'Blorf, F.-B. B. B. 1918. This reference title should have one author.', ref.authors_year_title
   assert_equal 'Blorf, F.-B. B. B. 1918. This reference title should have one author. Journal of Stuff and Things 1:1-123.', ref.render_full_citation
  end

  def test_two_auths
    ref2 = refs(:ref_rendering_test_2)
    assert_equal 'Blorf, F. B. B. B., and F. Blorf', ref2.authors_for_display
    assert_equal 'Blorf, F. B. B. B., and F. Blorf. 1918.', ref2.authors_year
    assert_equal 'Blorf, F. B. B. B., and F. Blorf. 1918. This reference title should have two authors.', ref2.authors_year_title
    assert_equal 'Blorf, F. B. B. B., and F. Blorf. 1918. This reference title should have two authors. Journal of Stuff and Things 1:124.', ref2.render_full_citation
  end
  
  def test_multiple_auths
    ref3 = refs(:ref_rendering_test_3)
    assert_equal 'Blorf, F.-B., F. Blorf, and Blorf', ref3.authors_for_display # there is no first name for third author
    assert_equal 'Blorf, F.-B., F. Blorf, and Blorf. 1918.', ref3.authors_year
    assert_equal 'Blorf, F.-B., F. Blorf, and Blorf. 1918. This reference title should have three authors.', ref3.authors_year_title
    assert_equal 'Blorf, F.-B., F. Blorf, and Blorf. 1918. This reference title should have three authors. Journal of Stuff and Things 1:125-135.', ref3.render_full_citation
  end
  
  def test_render_full_citation_with_journal_and_no_serial
    assert_equal("Allman, S. L. 1939. Gazette of New South Wales.", refs(:ref1).render_full_citation)
  end
  
  def test_full_citation_journal_from_creation
  end

  def test_full_citation_book
  end

  def test_full_citation_book_part
  end

  def test_renumber_all
  end
  
  
  # Endnote batch parser tests

  def create_endnote_files
    # this has 5 references in it 
    @file_with_many = File.read(File.dirname(__FILE__) + '/../fixtures/test_files/simpleendnote_test.txt')

    @file_with_one =  "%0 Journal Article
              %T Something great happened Here
              %A OhBrother, F.
              %J Journal of Hymenoptera Research
              %V 3
              %P 1-222
              %D 1972"
  end

  def test_batch_endnote_file_exists
     create_endnote_files
     assert @file_with_many.size > 0
     assert @file_with_one.size > 0
  end
    
  def test_create_endnote_files_works
    create_endnote_files
    @r = Ref.new_from_endnote(:endtext => @file_with_one,:proj_id => $proj_id )
    assert_equal 1, @r.unmatched_rephs.size
  end
 
  def test_that_new_from_endnote_raises_if_no_text_to_parse
    @file =  ""
    assert_raise(Ref::RefBatchParseError) {Ref.new_from_endnote(:endtext => @file, :proj_id => $proj_id)}
  end
  
  def test_new_from_endnote_without_serials_returns_unmatched_serials
    create_endnote_files
    
    @endref = Ref.new_from_endnote(:endtext => @file_with_many, :proj_id => $proj_id)
    assert_equal 4, @endref.unmatched_serials.size
  end
  
  def test_serial_matching_in_new_from_endnote_works
    create_endnote_files 
    @endref = Ref.new_from_endnote(:endtext => @file_with_one, :proj_id => $proj_id)
    assert_equal 1, @endref.unmatched_serials.size
    assert_equal 0, @endref.matched_serials.size
  end
  
  def test_new_from_endnote_that_refs_with_existing_titles_are_matched
    create_endnote_files 
    s = Serial.create!(:name => "Journal of Hymenoptera Research")  
    Ref.create!(:ref_type => "Journal Article", :title => "Something great happened Here", :serial => s)
    @endref = Ref.new_from_endnote(:endtext => @file_with_one, :proj_id => $proj_id)
    assert_equal 1, @endref.matched_rephs.size 
    assert_equal 0, @endref.unmatched_rephs.size
  end
 
  def test_new_from_endnote_that_references_are_created_on_save
    create_endnote_files
    @refs = Ref.new_from_endnote(:endtext => @file_with_many, :save => true, :proj_id => $proj_id)
    assert_equal 5, @refs.saved_rephs.size # includes the one book
    assert_equal "Phylogeny of Aculeata: Chrysidoidea and Vespoidea (Hymenoptera)", @refs.saved_rephs.first.ref.title
  end

end
