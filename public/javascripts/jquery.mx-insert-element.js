/*
 * On click of an element, this will insert a given string of HTML data into the DOM
 * according to a selector
 */

(function ($) {
  $.fn.mx_insert_element = function() {
    if (!this.length) {   return this; }
    return this.each(function() {
      var $this = $(this);
      var content = $this.data('insertContent');
      var parent   = $this.data('insertParent');
      var selector = $this.data('insertTarget');
      $this.click(function(evt) {
        $this.closest(parent).find(selector).append($(content));
        evt.preventDefault();
      });
    });
  };
})(jQuery);
