// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function bind_class_to_spinner(class_to_bind, spinner_class) {
    // See http://tesoriere.com/2011/05/19/rails-3.1-%26%238212%3B-fixing-the-%27ajax-loading%27-event/
    $('.'+class_to_bind).bind('ajax:beforeSend', function() {
        $('.'+spinner_class).toggle()
        } );
    // When the spinner is nested this below get hit
    $('.'+class_to_bind).bind("ajax:complete",  function() {
        $('.'+spinner_class).toggle()
        } );
}

function initialize_js(root) {
  var $root = $(root);
  var find = function(expr){
    return $($root).is(expr) ? $(expr, $root).add($root) : $(expr, $root);
  };
  find('.mx-autocomplete').mx_autocompleter();
  find("a[data-ajaxify], input[data-ajaxify]").ajaxify();
  find("input[data-color-picker]").mx_color_picker();
}
//
$(document).ready(function(){
  initialize_js($("body"));
});
