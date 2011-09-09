// This will handle
(function($) {
  $.mx_flash = function() {
    var flash_target = $('body');
    flash_target.ajaxComplete(function(data, xhr, settings) {
      if (! xhr || typeof xhr === 'undefined') {
        return this;
      }

      var content = [];
      var flash = $.parseJSON(xhr.getResponseHeader('X-JSON'));

      if (flash) {
        $.each(flash, function(k, v) {
          $.each(v,function(index,msg) {
            $.n(msg, {'type':k, 'stick':false});
          });
        });
      }
    });
  };
})(jQuery);
