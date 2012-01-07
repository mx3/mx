// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function initialize_js(root) {
  var $root = $(root);
  var find = function(expr){
    return $($root).is(expr) ? $(expr, $root).add($root) : $(expr, $root);
  };
  find("a[data-ajaxify], input[data-ajaxify]").ajaxify();
  find("input[data-color-picker]").mx_color_picker();
  find('*[data-mx-autocomplete-url]').mx_autocompleter();
  find("*[data-insert-content]").mx_insert_content();
  find("*[data-sortable]").mx_sortable();
  find("*[data-tooltip]").mx_tooltip();
  find("*[data-observe-field]").mx_field_observer();
  find("*[data-observe-select]").mx_select_observer();
  find("*[data-basic-modal]").basicModal();
  find("*[data-inplace-editor]").mx_inplace_editor();
}


$(document).ready(function(){
  initialize_js($("body"));
  $('body').mx_flash();

  // Attach to the mx_spinner -- any link-to-remotes will trigger this spinner effect.
  $("form[data-remote],a[data-remote],input[data-remote]")
    .bind('ajax:before', function() {
      $('body').mx_spinner('show');
    })
    .bind('ajax:complete', function() {
      $('body').mx_spinner('hide');
    });
});
