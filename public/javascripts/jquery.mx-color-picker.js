/*
 */

(function ($) {
  $.fn.mx_color_picker = function(options) {
    if (!this.length) {   return this; }
    return this.each(function() {
      var $this = $(this);
      $this.ColorPicker({
        onChange: function(hsb, hex, rgb, el) {
          $(this.data('colorpicker').el).val(hex);
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
    });
  };
})(jQuery);
