/*
 */
(function ($) {
  $.fn.mx_sticky_header = function() {
    if (!this.length) {   return this; }
    return this.each(function() {
      $(this).waypoint( function( evt, direction) {
        $(this).toggleClass('sticky', direction === 'down');
    	}
      );
    });
  };
})(jQuery);
