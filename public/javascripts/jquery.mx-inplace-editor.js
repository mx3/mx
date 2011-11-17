/*
 *  In place editor plugin for MX
 *
 *  To activate, add the data-inplace-editor tag onto a div/span/etc.
 *
 *  Possible data parameters are:
 *  data-inplace-editor-type = textarea  / nothing => input
 *    This defines whether it should be a textarea or an input eventually maybe select or other inputs?
 *  data-inplace-editor-text = The starting text for the input once the inplace editor is fired.
 *  data-inplace-editor-url  = The URL we POST to.  the content of the edit area is sent as 'value'.  In addition to whatever the URL says.
 *
 *  Requirements from the server are that it accept the :value parameter and return one of two things:
 *  The HTML to replace the body of the inplace-editor field with (if all is well).
 *  A 4XX response code when there is an error -- (and be a good citizen and push up an error flash message)
 *
 *  Example:
 *  <div
 *    data-inplace-editor
 *    data-inplace-editor-type='textarea'
 *    data-inplace-editor-text="<%= @record.field) %> "
 *    data-inplace-editor-url='<%= url_for(:foo=>1, :bar=>2)%>'
 *    >
 *      <%= @record.field.blank?  ? "No field present" : @record.field %>
 *    </div>
 *
 */

(function ($) {
  $.fn.mx_inplace_editor = function() {
    if (!this.length) {   return this; }
    var f = {
      create_input: function(el) {
        var div = el.data('inplace-editor-div');
        if (!div) {
          div = $("<div class='inplace-editor-controls'>");
          var input_type = el.data('inplaceEditorType');
          var input = null;

          /*  Determine what input field to create
           * And create it... most customization can be done here...
           */
          if (input_type == 'textarea') {
            var new_height = Math.max(30, el.height());
            input = $("<textarea name='data' class='inplace-editor-edit-field'/>")
              .width(el.width())
              .height(new_height);

          } else {
            input = $("<input type='text' name='data' class='inplace-editor-edit-field'>")
              .width(el.width())
              .height(el.height());
          }

          // Set the value from the .text() value of the inplace-editor source.
          // Can set data-inplace-editor-text if you want to specify
          if (el.data('inplaceEditorText')){
            input.val(el.data('inplaceEditorText'));
          } else {
            input.val(el.text());
          }


          // If it's a string length or something... we can detect through data attrs which to do,
          //   input or text area , or select, etc.
          var submit = $("<button>Ok</button>").click(function() {f.submit_input(el);});
          var cancel = $("<button>Cancel</button>").click(function() {f.hide_input(el);});

          div.append(input);
          div.append(cancel);
          div.append(submit);
          el.data('inplace-editor-div', div);

          el.after(div);
        }

        div.show();
        // Auto focus and then select
        div.find('.inplace-editor-edit-field').focus().select();

        el.hide();
      },
      submit_input: function(el) {
        var url  = el.data('inplaceEditorUrl');
        var editor_div = el.data('inplace-editor-div');

        editor_div.mx_spinner();
        var val = editor_div.find('.inplace-editor-edit-field').val();

        $.ajax({
          type: 'POST',
          url: url,
          data: {value: val},
          success: function(resp) {
            // We need to update the field.  But also hide the inputs.
            // If you decide to 'reedit' the input, we'll just show the input fields again.
            // Which should be === to what you have right now
            el.html(resp);
            f.hide_input(el);
            el.mx_effect('highlight');
          },
          error: function(resp) {
            editor_div.mx_effect('error_shake');
          },
          complete: function() {
            editor_div.mx_spinner('hide');
          }
        });
      },
      hide_input: function(el) {
        el.data('inplace-editor-div').hide();
        el.show();
      }
    };
    return this.each(function() {
      var $this = $(this);
      var options = {
        hoverClass: 'inplace-hover'

      };

      // First we want to add some classes on mouse over  / mouseout
      $this.mouseenter(function() { $this.addClass(options.hoverClass);     });
      $this.mouseleave(function() { $this.removeClass(options.hoverClass);  });

      // On click - create the input
      $this.click(function(){
        f.create_input($this);
      });

    });
  };
})(jQuery);
