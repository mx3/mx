/*
 */

(function ($) {
  $.fn.mx_color_picker = function(options) {
    if (!this.length) {   return this; }
    return this.each(function() {
      var $this = $(this);
      var set_color_swatch = function(color) {
          $this.val(color)
            .css('border', '1px solid #'+color)
            .css('borderRightWidth', '18px');
      };
      $this.ColorPicker({
        onChange: function(hsb, hex, rgb, el) {
          set_color_swatch(hex);
        },
        onSubmit: function(hsb, hex, rgb, el) {
          $(el).val(hex);
          $(el).ColorPickerHide();
        },
        onBeforeShow: function () {
          $(this).ColorPickerSetColor(this.value);
        }
      })
      .bind('keyup', function(){
        $(this).ColorPickerSetColor(this.value);
      });

      set_color_swatch($this.val());
    });
  };
})(jQuery);
