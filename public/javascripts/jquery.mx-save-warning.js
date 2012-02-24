// jQuery save_warning plugin
//
// When attached to an input element (or any element really) - it observes the on_change
// event, and when that event is fired - it will attach a css class to the element
// The element to attach to is either this element, or an element provided in the data-params
//
// There is also an ability to prevent the page from unloading until a confirmation button is
// pressed - if you deem it necessary.  You can specify if
//
// PARAMETERS:
// data-save-warning will activate the save-warning plugin for the element
// class_on_change = $this.data('saveWarningClass') || 'save-warning';
//
// selector_on_change = $this.data('saveWarningSelector');
// This will call $this.closest(selector_on_change);
//
// confirm_before_leaving = $this.data('saveWarningConfirm');
// If you want to prevent them from leaving the page if there were unsaved changes.
//
// This is some example HTML to use to show you how this puppy works.
/*
      <style>
        .save-warning {
          box-shadow: 0px 0px 6px red;
          border: 1px solid red;
          background: rgba(255,0,0,0.2);
        }
      </style>
      <h1> Test Save Warning</h1>

      <h3> Changing these do not prevent you from leaving the page </h3>
      <input data-save-warning type='input'> </input>

      <select data-save-warning type='input'>
        <option> Foo </option>
        <option> Bar </option>
      </select>

      <textarea data-save-warning>
      </textarea>

      <h3> Changing these prevent you from leaving the page w/o a dialog</h3>
      <input data-save-warning data-save-warning-confirm=true type='input'> </input>
      <select data-save-warning data-save-warning-confirm=true>
        <option> Foo </option>
        <option> Bar </option>
      </select>

      <textarea data-save-warning data-save-warning-confirm=true>
        This is a text area.
      </textarea>

      <h3> Example of changing a parent div element when it changes </h3>
      <div class='container'>
        <fieldset >
          <legend> Radio Buttons (need to have an outer element, b/c can't style them directly</legend>
          <input data-save-warning data-save-warning-selector='.container' type='radio' name='foo2' value="Option1" selected></input>
          <input data-save-warning data-save-warning-selector='.container' type='radio' name='foo2' value="Option2" ></input>
        </fieldset>
      </div>
*/

(function($) {
  var all_elements_with_save_warning = [];


  // The beforeunload handler works by presenting a dialog box
  // to the user before the page leaves to ask if they want to leave with unsaved
  // data still floating about.
  $(window).bind('beforeunload', function(e){
    // Only do this on elements which are visible.
    // So if the element is replaced on an update - it will be ignored
    // in this test.
    all_elements_with_save_warning = $.grep(all_elements_with_save_warning, function(e) {
      return $(e).is(":visible");
    });

    if (all_elements_with_save_warning.length === 0 ) {
      return;
    } else {
      return "There were elements on the page that were not saved.  If you would like to save them before leaving please press Cancel / Stay On Page and save them";
    }
  });
  var get_value = function(e) {
    if (e.is("input[type=radio]")) {
      console.log($("input[name=" + e.attr('name') + "]:checked"));
      return $("input[name=" + e.attr('name') + "]:checked").val();
    } else {
      return e.val();
    }
  };

  $.fn.mx_save_warning = function() {
    return this.each(function() {
      var $this = $(this);
      var class_on_change = $this.data('saveWarningClass') || 'save-warning';
      var selector_on_change = $this.data('saveWarningSelector');
      var confirm_before_leaving = $this.data('saveWarningConfirm');
      var original_value = get_value($this);

      // Attach to the onchange for this element
      $this.bind('change keyup click', function(e) {
        // Add the class to the selector element
        var element_to_add_class_to = $this;

        if (selector_on_change) {
          element_to_add_class_to = $this.closest(selector_on_change);
          console.log(element_to_add_class_to);
        }

        // Remove it -- we may add it back later if it changed
        all_elements_with_save_warning.splice(all_elements_with_save_warning.indexOf($this),1);

        // Remove the class
        element_to_add_class_to.removeClass(class_on_change);

        // value
        var now_value = get_value($this);
        if (original_value !== now_value) {
          element_to_add_class_to.addClass(class_on_change);
          if (confirm_before_leaving) {
            all_elements_with_save_warning.push($this);
          }
        }
      });
    });
  };
})(jQuery);
