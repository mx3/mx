
(function($) {
  $.fn.inline_form = function() {
    if (!this.length) {   return this; }
    return this.each(function() {
      var $this = $(this);
      var content = $($this.data('inlineForm'));
      // We convert the link into a div wrapper, with some
      // <div>
      //   <a> (existing link) </a>
      //   <div> </div>
      // </div>
      var wrapper = $this.wrap("<div class='inline-form-wrapper'>").parent();
      var content_div = $("<div class='inline-form-content'>").hide();
      wrapper.append(content_div);

console.log(wrapper);
      // Watch for the click event - which will show the form if it's not shown
        // then insert to the content div
        // initialize_js
        // .html(content)
        // look for .close-form or some class, like modals, and that will close the inline one.
      // Watch for a close event, or a ajax completed event.
        // then hide the div.

    });
  };
}(jQuery));
