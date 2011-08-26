/*
 * This attaches to an input element using the jquery autocompleter.
 * It reads off the data-mx-autocomplete-url variable, so set that:
 *
 * <input type="text" data-mx-autocomplete-url="/url/to/autocomplete">
 *
 * TODO:
 *   add --none-- when there are no values returned.
 */

(function ($) {
  $.fn.mx_autocompleter = function(options) {
    if (!this.length) {   return this; }
    return this.each(function() {
      var $this = $(this);
      var url = $this.data('mxAutocompleteUrl');

      console.log('init autocompleter ' + url);

      $this.autocomplete({
        source: url,
        minLength: 1,
        appendTo: $this.parent()
      })
      /* Need to just slam the HTML in there. :) */
      .data( "autocomplete" )._renderItem = function( ul, item ) {
        return $( "<li></li>" )
          .data( "item.autocomplete", item )
          .append( item.label ) // Just add the HTML from the label in directly
          .appendTo( ul );
      };
    });
  };
})(jQuery);
