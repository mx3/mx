/*
 *  Mx_Spinner will spin against an element it is called on.
 *
 *  Or against an element -- if defined on that element.
 */
(function ($) {
  $.fn.mx_spinner = function(action) {
      if (!this.length) {   return this; }
      return this.each(function() {
        var target = $(this);
        var overlay =  target.data('mx_spinner');

        if (overlay) {
          overlay.remove();
        }
        target.data('mx_spinner', null);

        if (action != 'hide') {
          var offset = target.offset();
          overlay = $("<div>&nbsp;</div>")
                        .outerWidth(target.outerWidth())
                        .outerHeight(target.outerHeight())
                        .css('left', offset.left)
                        .css('top', offset.top)
                        .css('margin', target.css('margin'))
                        .addClass('mx-spinner');
          target.data('mx_spinner', overlay);
          target.append(overlay);
        }
    });
  };
})(jQuery);
