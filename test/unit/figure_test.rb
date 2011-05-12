require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class FigureTest < ActiveSupport::TestCase

  # several of the tests here are mashups of OntologyClass and OntologyRelationship, if in doubt place place/leave these here
  
  def setup
    set_before_filter_vars
    @proj = Proj.find($proj_id) 
    @image_stub = MorphbankImage.create!(:mb_id => 2, :width => 20, :height => 20) 
    @figure_target = Otu.create!(:name => "Foo")
  end

  test "svg renders with no markers" do
    @figure = Figure.create_new(:obj => @figure_target, :image_id => @image_stub.id) 
    doc = REXML::Document.new( @figure.svg)
    assert_equal ["display", "height", "id", "width", "xlink", "xmlns"], doc.first.attributes.keys.sort
    assert_equal [], REXML::XPath.match(doc, "//path") # 
  end

  test "update_attributes works with multiple figure markers" do 
    marker1 = "<g><g><path d='M45.146,0'/><line/><path d='M45.146,545.833c277.083-12.5,529.167-237.5,277.083-12.5'/><path d='M45.576,981.069c73.222,65.419,191.748,75.395,284.815,79.097 c35.428,1.409,71.751,6.826,98.03-21.03c17.926-19.002,24.608-44.163,27.331-69.295c7.171-66.199-19.154-149.805-63.947-199.339 c-48.352-53.471-112.551-66.284-182.087-61.805c-45.041,2.901-94.381,22.692-126.955,54.689 c-26.689,26.217,5.757,74.864-26.983,97.873c-22.005,15.438-55.247,7.029-55.28,41.36 C0.472,931.311,25.504,963.135,45.576,981.069z'/></g></g>"
    marker2 = "<path d='M45.146,545.833c277.083-12.5,529.167-237.5,277.083-12.5'/>"

    @figure = Figure.create_new(:obj => @figure_target, :image_id => @image_stub.id) 

    assert @figure.update_attributes( "figure_marker_attributes"=>[{"position"=>"0", "svg" => marker1}, {"position"=>"0", "svg" => marker2}] )
    @figure.reload
    assert_equal 2, @figure.figure_markers.size

    assert @figure.update_attributes("figure_marker_attributes"=>[{ :id => @figure.figure_markers.first.id.to_s, "svg" => marker1}, {"svg" => marker2}] )
    @figure.reload
    assert_equal 3, @figure.figure_markers.size

    assert @figure.update_attributes("figure_marker_attributes"=>
                                     [{"position"=>"1", "svg" => "<path d='M45.146,545.833c277.083-12.5,529.167-237.5,277.083-12.5'/>", "id"=>"1"},
                                      {"svg" => "<g><g><path d='M45.146,0'/><line/><path d='M45.146,545.833c277.083-12.5,529.167-237.5,277.083-12.5'/><path d='M45.576,981.069c73.222,65.419,191.748,75.395,284.815,79.097 c35.428,1.409,71.751,6.826,98.03-21.03c17.926-19.002,24.608-44.163,27.331-69.295c7.171-66.199-19.154-149.805-63.947-199.339 c-48.352-53.471-112.551-66.284-182.087-61.805c-45.041,2.901-94.381,22.692-126.955,54.689 c-26.689,26.217,5.757,74.864-26.983,97.873c-22.005,15.438-55.247,7.029-55.28,41.36 C0.472,931.311,25.504,963.135,45.576,981.069z'/></g></g>"}, {}])
  end

end
