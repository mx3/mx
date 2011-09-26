/*
 */
(function ($) {
  $.mx_spinner = function(selector) {
    $('body').delegate(selector, "ajax:before", function() {
      $.basicModal('loading');
    });
    $('body').delegate(selector, "ajax:complete", function() {
      $.basicModal('hide');
    });
  };
})(jQuery);
