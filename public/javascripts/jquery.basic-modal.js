// jQuery Basic Modal
//
//
(function($) {
  var options = {
    overlay_class: 'basic-modal-overlay',
    overlay_color: '#aeaeae',
    overlay_spinner: '/images/modal_spinner.gif',
    overlay_opacity: '0.7',
    overlay_zindex:  '3000',
    overlay_parent:  'body',
    modal_class: 'basic-modal',
    modal_fade_speed:  100,
    event_target:  "body",
    close_button_class: "basic-modal-close",
    on_show:       initialize_js
  };

  var basicModal = {
    // Only 1 modal allowed for now... might 'stack' them in the future?
    get_modal: function(new_modal) {
      if (new_modal) {
        $('body').data('basicModalContent', new_modal);
      }
      return $('body').data('basicModalContent');
    },
    create_modal: function() {
      if (basicModal.get_modal()) {
        basicModal.get_modal().remove();
      }

      var modal = $("<div>");
      modal.addClass(options.modal_class)
        .css({
          position: 'fixed',
          height: "100%",
          width: "100%",
          top: "0",
          opacity: '1.0'
        })
        .delegate("."+options.close_button_class, "click", function() {
          basicModal.hide();
        });

      basicModal.get_modal(modal);

      var box =
        $("<div class='modal-box'>")
          .css({
            "position": "relative",
            "margin":   "50px auto",
            "padding":  "10px",
            "background": "white",
            "border-radius": "10px",
            "-moz-border-radius": "10px",
            "-webkit-border-radius": "10px",
            "-moz-box-shadow": "10px 10px 10px #000", /* Firefox */
            "-webkit-box-shadow": "10px 10px 10px #000", /* Safari, Chrome */
            "box-shadow": "10px 10px 10px #000" /* CSS3 */
          });

      modal.append(box);
      $(options.overlay_parent).append(modal);
      return box;
    },
    create_overlay: function() {
      var overlay = $('<div>');
        overlay
        .addClass(options.overlay_class)
        .css({
          height: '100%',
          width:  '100%',
          position: 'fixed',
          top:      '0',
          left:     '0',
          backgroundColor: options.overlay_color,
          backgroundImage: "url("+options.overlay_spinner+")",
          backgroundPosition: 'center 50px ',
          backgroundRepeat:   'no-repeat',
          opacity:         options.overlay_opacity,
          zIndex:          options.overlay_z_index
        })
        .appendTo($(options.overlay_parent))
        .click(function() {
          basicModal.hide();
        });

        return overlay;
    },
    get_overlay: function () {
      var overlay = $('body').data('basicModalOverlay');

      if (!overlay) {
        overlay = basicModal.create_overlay();
        $('body').data('basicModalOverlay', overlay);
      }
      return overlay;
    },
    hide: function() {
      var modal = basicModal.get_modal();
      if (modal) {
        modal.fadeOut(options.modal_fade_speed);
      }

      var overlay = basicModal.get_overlay();
      if (overlay) {
        overlay.hide();
      }

      $(options.event_target).trigger("basicModal:hide");
    },
    loading: function() {
      basicModal.get_overlay().show();
      if (basicModal.get_modal()) {
        basicModal.get_modal().hide();
      }
      $(options.event_target).trigger("basicModal:loading");
    },
    // Create the content box and add this content into it.
    show: function(show_options) {
      var content = show_options.content,
          anchor = show_options.anchor;

      if (!content) {
        content= show_options;
        anchor = null;
      }

      if (basicModal.get_overlay().is(":visible")) {
        var modal = basicModal.create_modal()
          .css({visibility: 'hidden'});
        try {
          modal.html(content);
        } catch (e) {
          modal.html(e);
        }
        if (options.on_show) {
          options.on_show(modal);
        }
        var padding = (modal.css('padding-left') !== '' ? parseInt(modal.css('padding-left'), 10) : 0) +
                      (modal.css('padding-right') !== '' ? parseInt(modal.css('padding-right'), 10) : 0);
        if ($.trim(modal.html()) === "") {
          // Don't show the thing!
          $.basicModal('hide');
        } else {
          var width = (modal.children().first().outerWidth() + padding) + "px";

          modal.css({
              visibility: 'visible',
              width: width
            });
        }
        $(show_options.event_target).trigger("basicModal:show", content);
      }
    }
  };

  // Actions
  $.basicModal = function(action,options) {
    if (action == 'show') {
      basicModal.show(options);
    } else if (action == 'loading') {
      basicModal.loading();
    } else if (action == 'hide') {
      basicModal.hide();
    } else if (action == 'error_shake' ) {
      basicModal.get_modal().mx_effect('error_shake');
    }
  };

  $.fn.basicModal = function(options) {
    if (!this.length) {   return this; }
    return this.each(function() {
      var $this = $(this);
      $this.click(function(evt) {
        $.basicModal('loading');

        var url = null;
        var type = 'GET';
        var data = null;

        if ($this.is("a")) {
          url = $this.attr("href");
        } else {
          var form = $this.closest('form');
          url = form.attr('action');
          type = form.attr('method');
          var tmp = $("<input type='hidden'>")
                    .attr('name', $this.attr('name'))
                    .attr('value', $this.attr('value'));
          data = form.serialize(true);
        }

        // Do the AJAX request to the HREF in the anchor
        $.ajax({
            url: url,
            type: type,
            data: data,
            dataType: "html",
            success: function(data) {
              $.basicModal('show', {'content':data, 'anchor':$this});
            },
            error: function(jqXhr, status, errorThrown) {
              $.basicModal('hide');
            }
        });
        evt.preventDefault();
      });
    });
  };
})(jQuery);
