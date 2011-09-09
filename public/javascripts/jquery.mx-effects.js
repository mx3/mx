/*
 */

(function ($) {
  $.fn.mx_effect = function(type, options) {
    if (!this.length) {   return this; }
    return this.each(function() {
      switch (type) {
        case 'error_shake':
        $(this).effect("shake", {times: 3 }, 50);
        break;
      }
    });
  };
})(jQuery);
