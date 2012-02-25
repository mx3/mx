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
  find("*[data-sticky-header]").mx_sticky_header();
  find("*[data-sortable-table]").mx_sortable_table();
  find("*[data-save-warning]").mx_save_warning();
  find("*[data-autoquery]").mx_autoquery();
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

/* Replace the DOM element and then inject the content */
function mx_replace(element, content) {
  $(element).replaceWith(content);
  initialize_js($(element));
}

function mx_update(element, content) {
  $(element).html(content);
  initialize_js($(element));
}

// parseUri 1.2.2
// (c) Steven Levithan <stevenlevithan.com>
// MIT License
function parseUri (str) {
	var	o   = parseUri.options,
		m   = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
		uri = {},
		i   = 14;

	while (i--) uri[o.key[i]] = m[i] || "";

	uri[o.q.name] = {};
	uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
		if ($1) uri[o.q.name][$1] = $2;
	});

	return uri;
};

parseUri.options = {
	strictMode: false,
	key: ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],
	q:   {
		name:   "queryKey",
		parser: /(?:^|&)([^&=]*)=?([^&]*)/g
	},
	parser: {
		strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
		loose:  /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
	}
};
