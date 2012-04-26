require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class ConfidencesControllerTest < ActionController::TestCase
  def setup
    login
    super
  end

  # just testing loads
  def test_index
    get :index, :proj_id=>@proj.id
    assert_response :success
  end
  def test_index_shows_3_records
    confidences = Confidence.make!(3, :proj => @proj)
    get :index, :proj_id=>@proj.id
    assert_select "li.confidence", confidences.size
  end

  def test_show
    confidence = Confidence.make!(:proj => @proj)
    get :show, :proj_id=>@proj.id, :id=> confidence.id
    assert_response(:success)
  end

  def test_edit
    confidence = Confidence.make!(:proj => @proj)
    get :edit, :proj_id=>@proj.id, :id=>confidence.id
    assert_response(:success)
    assert_select "input[value='#{confidence.html_color}']", 1
  end

  def test_new
    get :new, :proj_id=>@proj.id
    assert_response :success
  end

  def test_create
    assert_difference "Confidence.count" do
      post :create, :proj_id=>@proj.id, :confidence => {:applicable_model=>Confidence::MODELS_WITH_CONFIDENCE.values.sample,
                      :applicable_model=>Confidence::MODELS_WITH_CONFIDENCE.values.sample,
                      :name=>'confidence'}
      assert_redirected_to confidence_path(@proj, Confidence.last)
    end
    assert_equal "confidence", Confidence.last.name
  end

  def test_destroy
    confidence = Confidence.make!(:proj => @proj)
    assert_difference "Confidence.count", -1 do
      get :destroy, :proj_id=>@proj.id, :id=>confidence.id
      assert_response :redirect
    end
  end

  def test_merge_without_merge_with
    start = Confidence.make!(:proj => @proj)
    merged = Confidence.make!(:proj => @proj)
    assert_no_difference "Confidence.count" do
      post :merge, :proj_id => @proj.id, :id=>start.id
      assert_response :redirect
    end
  end
  def test_merge
    start = Confidence.make!(:proj => @proj)
    merged = Confidence.make!(:proj => @proj)
    post :merge, :proj_id => @proj.id, :merge_with => {:id=>merged.id}, :id=>start.id
    assert_response :redirect
  end

  test "popup link gives modal dialog" do
    pcr = Pcr.make!(:proj => @proj)
    get :popup, :confidence_obj_class => pcr.class.to_s, :confidence_obj_id => pcr.id, :html_selector => "body_123", :proj_id=>@proj.id
    assert_response :success
  end

  test "popup update works from modal dialog" do
    pcr = Pcr.make!(:proj => @proj)
    confidence_2 = Confidence.make!(:proj=>@proj)
    xhr :post, :apply_from_popup, :confidence=>{:id=>confidence_2.id}, :obj_class => pcr.class.to_s, :obj_id => pcr.id, :html_selector => "body_123", :proj_id=>@proj.id
    assert_response :success
    pcr.reload
    assert_equal confidence_2.id, pcr.confidence_id
  end
  test "popup update works to clear from modal dialog" do
    pcr = Pcr.make!(:proj => @proj)
    xhr :post, :apply_from_popup, :confidence=>{:id=>'-1'}, :obj_class => pcr.class.to_s, :obj_id => pcr.id, :html_selector => "body_123", :proj_id=>@proj.id
    assert_response :success
    pcr.reload
    assert_equal nil, pcr.confidence_id
  end
end
