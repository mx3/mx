/*
 *  mx-select-observer will observe selects for change,
 *  and fire off an request based on the "task" 
 *
 *  Tasks: 
 *    'submitForm' -> submits the form the select is part of as an AJAX query to observeFieldAction 
 *    'submitSelfAsId' -> submits self with value as params[:id] to observeFieldAction
 *
 */
(function ($) {
  $.fn.mx_select_observer = function() {

    if (!this.length) { return this; }

    return this.each(function() {
      var $source = $(this);
      var frequency= $source.data('observeFieldFrequency') || 0.5;
      var url      = $source.data('observeFieldAction');
      var spinner_target = $($source.data('observeFieldSpinnerTarget') || $source);
      var task = $($source.data('observeFieldTask') || $source);  
    // var value = var task = $($source.data('observeFieldTask') || $source);  

      $source.data('observeFieldActive', true);

      switch (task) { 
        case 'submitForm':
          $source.change(function(evt) {
            $source.closest('form').submit();
          });
        break; 
  
        case 'submitSelfAsValue':
          alert("FOO!");
        break;
      }

    });
  };
})(jQuery);

