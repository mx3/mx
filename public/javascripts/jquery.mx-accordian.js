/*

*/

(function ($) {
  $.fn.mx_accordian = function() {
    if (!this.length) {  return this; }

    return this.each(function() {
      var $this = $(this);

      $this.data('.head').click(function() {
        $(this).next().toggle('slow');
        return false;
      }).next().hide();

    });

  }
})(jQuery);



