/*
 *  mx-select-observer will observe selects for change,
 *  and fire off an request to submit the nearest form (needs to name form I suspect)
 *  used in one-click coding
 */
(function ($) {
  $.fn.mx_select_observer = function() {

    if (!this.length) { return this; }

    return this.each(function() {
      var $source = $(this);
      var frequency= $source.data('observeFieldFrequency') || 0.5;
      var url      = $source.data('observeFieldAction');
      var spinner_target = $($source.data('observeFieldSpinnerTarget') || $source);

      $source.data('observeFieldActive', true);

      $source.change(function(evt) {
        $source.closest('form').submit();
      });

    });
  };
})(jQuery);
