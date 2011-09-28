
/*
 * Attaches a mouseover to the given DOM element.
 * looks for data-tooltip = " .... "
 *
 */

(function ($) {
  $.fn.mx_tooltip = function() {
    if (!this.length) {   return this; }
    return this.each(function() {
      var $this = $(this);

      // we want to get the content to show
      // We'll do something simple here... if it leads with a / or http, we consider it
      // an AJAX URL.  Otherwise it's just inline content.
      var content = $this.data('tooltip');

      var defaults = {
        loading: {
          width: 100,
          height: 100,
          spinner: '/images/modal_spinner.gif'
        }
      };

      // Setup the tooltip object.
      var tooltip = {
        hiding: false,
        hide_tooltip: function() {
          this.hiding = true;

          setTimeout(function() {
            if (this.hiding) {
              this.el.hide();
            }
          }.bind(this), 750);
        },
        make_tooltip: function() {
          var pos = $this.position();
          var el = $("<div>", {'class':'mx-tooltip'});
          el.append((el.notch = $("<div>", {'class':'notch'})));
          el.append((el.content = $("<div>", {'class':'content'})));

          el.css({'position':'absolute',
                  'top' :  pos.top + $this.height() + 5 + "px",
                  'left':  pos.left+ $this.width() - 20 + "px"
                });

          el.mouseenter(function() { this.show(); }.bind(this));
          el.mouseover( function() { this.show(); }.bind(this));
          el.mouseout(  function() { this.hide(); }.bind(this));

          return el;
        },
        load: function() {
          if (/^\//.test(content)) {
            // Put up the loading div.
            this.el = this.make_tooltip();
            this.el.content.css({'width': defaults.loading.width + "px",
                                 'height':defaults.loading.height + "px",
                                 'background':"url("+defaults.loading.spinner+") center center no-repeat"
                });

            $.get(content, function(data) {
              this.el.content.html(data);
              this.el.content.css({'width': 'auto',
                                 'height':  'auto',
                                 'background':"none"});
            }.bind(this));
          } else {
            // Just show the tooltip
            this.el = this.make_tooltip(this.el);
            this.el.content.html(content);
          };
          $this.after(this.el);
        },
        show: function() {
          if (this.el) {
            this.hiding = false;
            this.el.show();
          } else {
            this.load();
          }
        },
        hide: function() {
          this.hide_tooltip();
        }
      };

      // Now we attach the mousein / mouseout / mouseovers
      $this.mouseenter(function() {
        tooltip.show();
      });
      $this.mouseover(function() {
        tooltip.show();
      });
      $this.mouseout(function() {
        tooltip.hide();
      });
    });
  };
})(jQuery);
