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

$(document).ready(function(){
  $('.mx-autocomplete').mx_autocompleter();
});
