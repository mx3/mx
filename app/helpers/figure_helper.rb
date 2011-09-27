# encoding: utf-8
module FigureHelper

  def figure_class(figure)
    "figure-class-#{figure.id}"
  end

  def illustrate_image_description_id(image_description)
    "id=\"image-search-id-#{image_description.id}\""
  end


  def create_figure_tag(options ={})
    opt = {
      :object => nil,        # required
      :image => nil,         # required
      :caption => nil,       #
      :link_text => 'Attach' #
    }.merge!(options)

    return content_tag(:em, opt[:link_text]) if opt[:object].nil? || opt[:image].nil?

    url = url_for(:action => :create,
                  :controller => :figure,
                  :html_selector => opt[:html_selector],      # Needed here?
                  :figure_obj_class => opt[:object].class.to_s,
                  :figure_obj_id => opt[:object].id,
                  :caption => opt[:caption],
                  :image_id => opt[:image].id
                  )

    # note the link has an ID that we can flash or higlight after the form it pops up successfully creates a new tag

    # Cary - TODO - this should call
    link_to(opt[:link_text], url, 'data-remote' => 'true', :method => 'post')
  end


  # collective renders appended figures on non-ajax loads
  def render_svged_figures # :yields: String (svgweb ineractive HTML)
    if !request.xml_http_request?
      update_page_tag do |page|
        page.call 'appendFigsToSvgonload'
      end
    end
  end

  def url_for_zoom_figure(figure) # :yields: String (URL)
    base = 'http://'
    pub_str = (@public ? '/public' : '' )
    if @server_name == 'development'
      base += '127.0.0.1:3000' +  url_for(:action => :show_zoom, :controller => (pub_str + '/figure'), :id => figure.id)
    else
       base += @server_name +  url_for(:action => :show_zoom, :controller => (pub_str + '/figure'), :id => figure.id)
    end
  end

  def figure_thumbnail_with_svg_tag(figure) # :yields: String
    content_tag(:div, :id => "figure_#{figure.id}_img", :class => 'image') do
      if figure.figure_markers.size > 0
        update_page_tag do |page|
          page.call 'createSvgObjRoot', (request.xml_http_request? ? 'ajax' : 'http'), *figure.svgObjRoot_params(:size => :thumb, :link => url_for_zoom_figure(figure) )
        end
      else
         content_tag(:a, image_thumb_tag(figure.image), :href => url_for_zoom_figure(figure), :target => '_blank', :alt => "mx_image_#{figure.image.id}")
      end
    end
  end

  def caption_tag(figure, size = :thumb) # :yields: String (<div> element containing enumerated figure caption)
    return "" if figure.caption.blank? && (size != :thumb) # maintain numbering for Content referencing with thumbs.
    content_tag :div, :style => "text-align: left; width: #{figure.image.width_for_size(size).to_i}px; height: 2em;" do
      figure.position.to_s + "." + expandable_caption((figure.caption.blank? ? '' : figure.caption), figure.id, figure.text_width_chrs)
    end
  end

  def img_legal_tag(figure) # :yields: String (of html or empty)
    image = Image.find(:first, :conditions => {:id => figure.image_id})
    return '' if image.license.blank? && image.copyright_holder.blank? # don't assume anything
    license = (image.license.blank? ? content_tag(:em, 'no Creative Commons license provided') : render(:partial => "content_licenses/#{image.license}"))
    content_tag(:div, :style => "background-color:#ccc;padding:5px; margin-top:2px;") do

      content_tag(:div, :style => "float:left;") do
        image.copyright_holder.blank? ? " <em>for &copy; contact site owners<em>" : "&copy; #{image.copyright_holder}"
      end  +

      content_tag(:div, :style => "float:right;") do
        license
      end +
     content_tag(:br)
   end
 end

  def link_to_figured(figure, link_text = 'show')
    return "<strong style='color:red'>ERROR? #{figure.addressable_type}:#{figure.addressable_id}</strong>" if !figure.figured_obj
    link_to(link_text, :action => :show_figures, :id => figure.addressable_id, :controller => figure.addressable_type.underscore)
  end

  def figured_object_tag(figure)
    [content_tag(:span, figure.addressable_type),
      content_tag(:span, "id:" + figure.addressable_id.to_s),
      content_tag(:span, figure.figured_obj ? figure.figured_obj.display_name : '<strong style="color:red;">ORPHANED FIGURE</strong>'),
      link_to_figured(figure)
    ].join("<br />")
  end

  # handles the <script wrapper>
  def svg_tag(options = {})
    opt = {
      :figure => nil,
      :target => ""
    }.merge!(options.symbolize_keys)

    return nil if opt[:figure].nil?

    xml = Builder::XmlMarkup.new(:indent=> 2, :target => opt[:target])

    xml.script(:type => 'image/svg+xml') {
      opt[:figure].svg(opt)
    }

    # this might need better logic for IE
    # see http://github.com/imanel/svg_web/blob/master/lib/svg_web.rb
    #   xml.script(:type => 'image/svg+xml') {

    #   }

    opt[:target].to_s
  end

  # TODO mx3: deprecate
  def fig_link(o)
    'DEPRECATED FOR figure_tag' #    render(:partial => "figure/fig_link", :locals => { :fig_obj_id => o.id, :fig_obj_class => o.class.to_s, :msg => ''})
  end

  # Pass an Instance of a Model that has include ModelExtensions::Figurable
  # mx3 uses "illustrate" as the verb, "figure" as the noun
  def illustrate_tag(o)
    if (o)
      content_tag :div, :id => "f_#{o.class.to_s}_#{o.id}", :style => 'display:inline;' do
        content_tag :span, :id => "fl_#{o.class.to_s}_#{o.id}" do
          content_tag(:a, 'Fig', 'data-basic-modal' => '', :href => url_for(:action => :illustrate, :controller => :figure, :fig_obj_id => o.id, :fig_obj_class => o.class.to_s) )
        end
      end
    end
  end

  def render_figs_for_obj(o, size = 'thumb', render_w_no_figs = true, klass = 'attached_figs', mb_annotation = false, mode = 'partial') # :yields: renders a Partial
    @obj = o
    @size = size
    @klass = klass
    @mb_annotation = mb_annotation
    @figures = @obj.figures

    return '' if @figures.size == 0

    # MODE IS A HACK
    # hmm- this needs to be :partial in some case, :templates in others?
    if mode == 'js'
      render(:template => '/figure/attached_figures') if render_w_no_figs || @figures.size > 0
    else
      render(:partial => '/figure/attached_figures') if render_w_no_figs || @figures.size > 0
    end
  end

end
