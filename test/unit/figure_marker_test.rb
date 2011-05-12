require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class FigureMarkerTest < ActiveSupport::TestCase

  # several of the tests here are mashups of OntologyClass and OntologyRelationship, if in doubt place place/leave these here

  def setup
    set_before_filter_vars
    @proj = Proj.find($proj_id) 
    @image_stub = MorphbankImage.new(:mb_id => 2, :height => 20, :width => 20) 
    @image_stub.save! 
    @figure_target = Otu.create!(:name => "Foo")
    @figure_stub = Figure.create_new(:obj => @figure_target, :image_id => @image_stub) 
  end

  test "that attributes are stripped on create" do
    @fm = FigureMarker.new(:figure => @figure_stub, :svg => '<path fill="#FFFFFF" stroke="#000000" d="M45.146,0"/>')
    @fm.save!
    assert_equal "<path d='M45.146,0'/>", @fm.svg
  end

  test "that attributes are added on render" do
    @fm = FigureMarker.new(:figure => @figure_stub, :svg => '<path fill="#FFFFFF" stroke="#000000" d="M45.146,0"/>')
    @fm.save!

    doc = REXML::Document.new(@fm.render(:stroke => '#123', :fill => '#456', :opacity => '0.3'))
    
    desired = "<g stroke='#123' fill='#456' id='marker_#{@fm.id}' display='inline' stroke-width='2' opacity='0.3'><path d='M45.146,0'/></g>"
    assert_equal desired, doc.to_s.gsub(/\n/,'')  
  end

  test "that attribute DEFAULT_OPACITY and other defaults are used on render" do
    @fm = FigureMarker.new(:figure => @figure_stub, :svg => '<path fill="#FFFFFF" stroke="#000000" d="M45.146,0"/>')
    @fm.save!

    doc = REXML::Document.new(@fm.render(:stroke => '#123', :fill => '#456'))
    
    desired = "<g stroke='#123' fill='#456' id='marker_#{@fm.id}' display='inline' stroke-width='2' opacity='#{FigureMarker::DEFAULT_OPACITY}'><path d='M45.146,0'/></g>"
    assert_equal desired, doc.to_s.gsub(/\n/,'')  
  end


  test "that lines are allowed" do 
    line ='<line fill="#FFFFFF" stroke="#000000" x1="0" y1="0" x2="200" y2="200" bad="123"/>'
    @fm = FigureMarker.new(:figure => @figure_stub, :svg => line)
    @fm.save!
    assert_equal "<line y1='0' y2='200' x1='0' x2='200'/>", @fm.svg

  end

  test "that cleanup works for multiple elements" do 
    elements = '<g><g><path fill="#FFFFFF" stroke="#000000" d="M45.146,0"/>
        <line fill="#FFFFFF" stroke="#000000" x1="49.313" y1="216.667" x2="453.479" y2="235.417"/>  
        <path fill="#FFFFFF" stroke="#000000" d="M45.146,545.833c277.083-12.5,529.167-237.5,277.083-12.5"/>
        <path fill="#FFFFFF" stroke="#000000" d="M45.576,981.069c73.222,65.419,191.748,75.395,284.815,79.097
         c35.428,1.409,71.751,6.826,98.03-21.03c17.926-19.002,24.608-44.163,27.331-69.295c7.171-66.199-19.154-149.805-63.947-199.339
         c-48.352-53.471-112.551-66.284-182.087-61.805c-45.041,2.901-94.381,22.692-126.955,54.689
         c-26.689,26.217,5.757,74.864-26.983,97.873c-22.005,15.438-55.247,7.029-55.28,41.36
         C0.472,931.311,25.504,963.135,45.576,981.069z"/></g></g>'

    @fm = FigureMarker.new(:figure => @figure_stub, :svg => elements)
    @fm.save!

    assert_equal "<g><g><path d='M45.146,0'/><line y1='216.667' y2='235.417' x1='49.313' x2='453.479'/><path d='M45.146,545.833c277.083-12.5,529.167-237.5,277.083-12.5'/><path d='M45.576,981.069c73.222,65.419,191.748,75.395,284.815,79.097 c35.428,1.409,71.751,6.826,98.03-21.03c17.926-19.002,24.608-44.163,27.331-69.295c7.171-66.199-19.154-149.805-63.947-199.339 c-48.352-53.471-112.551-66.284-182.087-61.805c-45.041,2.901-94.381,22.692-126.955,54.689 c-26.689,26.217,5.757,74.864-26.983,97.873c-22.005,15.438-55.247,7.029-55.28,41.36 C0.472,931.311,25.504,963.135,45.576,981.069z'/></g></g>", @fm.svg
    end

end
