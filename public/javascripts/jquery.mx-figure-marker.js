// This will handle ??
(function($) {
  $.fn.mx_figure_marker = function() {
    return this.each(function() {
      var $this = $(this);
      var functions = $this.data('figureMarker').split("|");
      var svg_tag   = $("#"+$this.data('figureMarkerId'));

      var handlers = {
        // This will toggle visibility of the SVG tag
        // when you click it
        "toggle-visibility": function() {
          var hide_text = "[Hide]";
          var show_text = "[Show]";
          $this.css('cursor', 'pointer');

          $this.on("click", function(e) {
            if (svg_hasClass(svg_tag, 'hide-element')){
              svg_removeClass(svg_tag, 'hide-element');
              $this.html(hide_text);
            } else {
              svg_addClass(svg_tag, 'hide-element');
              $this.html(show_text);
            }
          });

          if (svg_hasClass(svg_tag, 'hide-element')) {
            $this.html(show_text);
          } else {
            $this.html(hide_text);
          }
        },
        "highlight-hover": function() {
          $this.on('mouseenter', function(e) {
            svg_addClass(svg_tag, 'highlight');
          });
          $this.on('mouseleave', function(e) {
            svg_removeClass(svg_tag, 'highlight');
          });
        }
      };
      $.each(functions, function(i, func) {
        handlers[func]();
      });

    });
  };
})(jQuery);
