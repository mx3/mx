module App::ColorsHelper
  def convert_to_brightness_value(background_hex_color)
    (background_hex_color.scan(/../).map {|color| color.hex}).sum
  end

  def contrasting_text_color(background_hex_color)
    convert_to_brightness_value(background_hex_color) > 382.5 ? '#000' : '#fff'
  end
end
