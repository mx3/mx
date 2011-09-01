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
    modal_fade_speed:  200,
    event_target:  "body",
    close_button_class: "basic-modal-close"
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
          top: "0px",
          opacity: '1.0'
        })
        .click(function() {
          basicModal.hide();
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
        overlay.fadeOut(options.modal_fade_speed + 200);
      }

      $(options.event_target).trigger("basicModal:hide");
    },
    loading: function() {
      basicModal.get_overlay().show();
      $(options.event_target).trigger("basicModal:loading");
    },
    // Create the content box and add this content into it.
    show: function(options) {
      var content = options.content,
        anchor = options.anchor;

      if (!content) {
        content= anchor;
        anchor = null;
      }

      if (basicModal.get_overlay().is(":visible")) {
        var width = (anchor && anchor.data('basicModalWidth')) || "50%";
        basicModal.create_modal()
          .css({
            width: width
          })
          .hide()
          .fadeIn(options.modal_fade_speed)
          .html(content);
        $(options.event_target).trigger("basicModal:show", content);
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
    }
  };

  $.fn.basicModal = function(options) {
    if (!this.length) {   return this; }
    return this.each(function() {
      var $this = $(this);
      $this.click(function(evt) {
        $.basicModal('loading');

        // Do the AJAX request to the HREF in the anchor
        $.ajax({
            url: $this.attr('href'),
            type: 'GET',
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

$(document).ready(function(){
  $("a[data-basic-modal]").basicModal();
});
