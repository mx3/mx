module App::ColorPickerHelper
  def include_color_picker_js
    content_for :head, '<script src="/colorpicker/js/colorpicker.js" type="text/javascript"></script>'.html_safe

    content_for :head, '<link type="text/css" href="/colorpicker/css/colorpicker.css" rel="stylesheet" media="screen"/>'.html_safe
  end
end
