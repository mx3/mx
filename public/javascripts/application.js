// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//

// must bind to any remote_to :link that has a certain class

// jQuery(function($) {
//  var toggleLoading = function() { $("#<%= spinner_id -%>").toggle() };
//
//  $("#<%= link_id -%>")
//    .bind("ajax:loading",  toggleLoading)
//    .bind("ajax:complete", toggleLoading);
// });
 

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

//$(function() {
//  $("#products th a, #products .pagination a").live("click", function() {
//    $.getScript(this.href);
//    return false;
//  });
//  $("#products_search input").keyup(function() {
//    $.get($("#products_search").attr("action"), $("#products_search").serialize(), null, "script");
//    return false;
//  });
//});

/*
* Unobtrusive autocomplete
*
* To use it, you just have to include the HTML attribute autocomplete
* with the autocomplete URL as the value
*
* Example:
* <input type="text" data-autocomplete="/url/to/autocomplete">
*
* Optionally, you can use a jQuery selector to specify a field that can
* be updated with the element id whenever you find a matching value
*
* Example:
* <input type="text" data-autocomplete="/url/to/autocomplete" id_element="#id_field">
*/

$(document).ready(function(){
    $('input[data-autocomplete]').live('focus', function(i){
        $(this).autocomplete({
            source: $(this).attr('data-autocomplete'),
            select: function(event, ui) {
                $(this).val(ui.item.value);
                if ($(this).attr('id_element')) {
                    $($(this).attr('id_element')).val(ui.item.id);
                }
                return false;
            }
        });
    });
});




$(document).ready(function(){
    $('input[data-autocomplete]').railsAutocomplete();
});


(function(jQuery)
{
    var self = null;
    jQuery.fn.railsAutocomplete = function() {
        return this.live('focus',function() {
            if (!this.railsAutoCompleter) {
                this.railsAutoCompleter = new jQuery.railsAutocomplete(this);
            }
        });
    };

    jQuery.railsAutocomplete = function (e) {
        _e = e;
        this.init(_e);
    };

    jQuery.railsAutocomplete.fn = jQuery.railsAutocomplete.prototype = {
        railsAutocomplete: '0.0.1'
    };

    jQuery.railsAutocomplete.fn.extend = jQuery.railsAutocomplete.extend = jQuery.extend;
    jQuery.railsAutocomplete.fn.extend({
        init: function(e) {
            e.delimiter = $(e).attr('data-delimiter') || null;
            function split( val ) {
                return val.split( e.delimiter );
            }
            function extractLast( term ) {
                return split( term ).pop().replace(/^\s+/,"");
            }

            $(e).autocomplete({
                source: function( request, response ) {
                    $.getJSON( $(e).attr('data-autocomplete'), {
                        term: extractLast( request.term )
                    }, function() {
                        $(arguments[0]).each(function(i, el) {
                            var obj = {};
                            obj[el.id] = el;
                            $(e).data(obj);
                        });
                        response.apply(null, arguments);
                    });
                },
                search: function() {
                    // custom minLength
                    var term = extractLast( this.value );
                    if ( term.length < 2 ) {
                        return false;
                    }
                },
                focus: function() {
                    // prevent value inserted on focus
                    return false;
                },
                select: function( event, ui ) {
                    var terms = split( this.value );
                    // remove the current input
                    terms.pop();
                    // add the selected item
                    terms.push( ui.item.value );
                    // add placeholder to get the comma-and-space at the end
                    if (e.delimiter != null) {
                        terms.push( "" );
                        this.value = terms.join( e.delimiter );
                    } else {
                        this.value = terms.join("");
                        if ($(this).attr('id_element')) {
                            $($(this).attr('id_element')).val(ui.item.id);
                        }
                        if ($(this).attr('data-update-elements')) {
                            var data = $(this).data(ui.item.id.toString());
                            var update_elements = $.parseJSON($(this).attr("data-update-elements"));
                            for (var key in update_elements) {
                                $(update_elements[key]).val(data[key]);
                            }
                        }
                    }
                    // If a user changes the field after already making a selection make sure to remove id of a previous selection.
                    var remember_string = this.value;
                    $(this).bind('keyup.clearId', function(){
                        if($(this).val().trim() != remember_string.trim()){
                            $($(this).attr('id_element')).val("");
                            $(this).unbind('keyup.clearId');
                        }
                    });
                    $(this).trigger('railsAutocomplete.select');

                    return false;
                }
            });
        }
    });
})(jQuery);
