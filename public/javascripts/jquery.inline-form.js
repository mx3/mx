
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
      var content_div = $("<div class='inline-form-content'>");
      wrapper.append(content_div);

      // Watch for the click event - which will show the form if it's not shown
      $this .on('click', function(e) {
          mx_update(content_div, content);
          $this.hide();
        });

      wrapper
        .on('click', '.ajax-modal-close', function(e) {
          content_div.html('');
          $this.show();
        })
        // On an error - we shake it, and update with the response.
        .on('ajaxify:error',  function(e, data) {
          content_div.mx_effect('error_shake');
        })
        .on('ajaxify:success', function(e) {
          content_div.html('');
          $this.show();
        });
    });
  };
}(jQuery));
