
var figs = [];

// Create an new SVG root using 'object' (see svgweb) 
// if you pass 'body' to parentElementId object will be appended to <body>

// Usage: 
// In Rails
//   str = '<svg xmlns="http://www.w3.org/2000/svg" id="myRect8" width="100" height="100"><rect x="5" y="5" id="myRect4" rx="3" ry="10" width="15" height="15" fill="purple" stroke="yellow" stroke-width="2"/></svg>'
//   page.call 'createSvgObjRoot', (request.xml_http_request? ? 'ajax' : 'http'), 'body', 'myroot', str, 500, 500
// In mx
//   page.call 'createSvgObjRoot', (request.xml_http_request? ? 'ajax' : 'http'), *figure.svgObjRoot_params(:thumb)

function createSvgObjRoot(context, parentElementId, id, svgTag, width, height) {
  // as called in mx this never recieves undefined to context 
  if (context === 'http' || context == 'ajax') {
    var obj = document.createElement('object', true);
    obj.setAttribute('id', id); 
    obj.setAttribute('width', width);
    obj.setAttribute('height', height);

    var brwser = 'notIE';

    // see http://groups.google.com/group/svg-web/browse_thread/thread/fdc2bdd1c4345ffc/96c82b2724e5d9d6?lnk=gst&q=IE+object#96c82b2724e5d9d6
    // and thanks http://www.javascriptkit.com/javatutors/navigator.shtml

    if (/MSIE (\d+\.\d+);/.test(navigator.userAgent)){ //test for MSIE x.x;
     alert('Image with SVG overlays can not (yet) be displayed in Internet Explorer. Try Firefox, Safari, Chrome, or Opera.');
     var ieversion=new Number(RegExp.$1) // capture x.x portion and store as a number
     if (ieversion>8)
       brwser = 'IE9'
     else 
       brwser = 'IE'
    }

    // Dynamic addition of objects is not possible in IE yet (apparently)
    if (brwser == 'IE9') {
      //  <object data="helloworld.svg" type="image/svg+xml" width="200" height="200" id="mySVGObject"
      obj.setAttribute('data',  'data:image/svg+xml,' + svgTag); // <svg xmlns="http://www.w3.org/2000/svg">' + my_string + '</svg>');  
      obj.setAttribute('type', 'image/svg+xml');
    } else if (brwser == 'IE') {
      //  <object src="helloworld.svg" classid="image/svg+xml" width="200" height="200" id="mySVGObject"> 
      obj.setAttribute('classid', 'image/svg+xml');
      obj.setAttribute('src', svgTag); // <svg xmlns="http://www.w3.org/2000/svg">' + my_string + '</svg>');  
    } else {
      obj.setAttribute('data', 'data:image/svg+xml,' + svgTag); // <svg xmlns="http://www.w3.org/2000/svg">' + my_string + '</svg>');  
      obj.setAttribute('type', 'image/svg+xml');
    }

    figs.push(obj);  
    figs.push(parentObj(parentElementId));

    // need to tweak logic a little 
    if (context == 'http') {  // attach it to an onload
    window.onsvgload = function() {
       svgweb.appendChild(obj, parentObj(parentElementId));}
    } else { // javsacript is already loaded, just append 
      svgweb.appendChild(obj, parentObj(parentElementId)); 
    }

  } else {
    alert('internal error, createSvgObjRoot improperly called, contact an admin')
  }
}

function clearFigBucket() {
  figs = [];
}

// If there is more than one svged figure on a page you'll need to call 'render_svged_figures' to display them all for non-ajax calls
function appendFigsToSvgonload() {
  var total_figs = (figs.length / 2);
  window.onsvgload = function() {
    for (var i = 0; i < total_figs ; i++) {
      svgweb.appendChild(figs.shift(),figs.shift()); 
    }
  }
}

// The functions below are for notes purposes, not yet integrated in mx

// toggles b/w body or an Element
function parentObj(parentElementId) {
  if (parentElementId == 'body') {
    return document.body 
  } else {
    return document.getElementById(parentElementId);
  }
}

// if you pass 'body' to parentElementId object will be appended to <body>
function createSvgRoot(parentElementId, rootId, width, height) {
  var svg = document.createElementNS(svgns, 'svg'); 
  svg.setAttribute('id', rootId);
  svg.setAttribute('width', width);
  svg.setAttribute('height', height);
  svgweb.appendChild(svg, parentObj(parentElementId)); 
}


// if you pass 'body' to parentElementId object will be appended to <body>
function addPath(parentNodeId, id, d, fill, stroke, strokeWidth ) {
  var doc = document.getElementById(parentNodeId);
  var path = document.createElementNS(svgns, 'path'); 
  path.setAttribute('id', id);
  path.setAttribute('d', d);
  path.setAttribute('fill', fill);
  path.setAttribute('stroke', stroke);
  path.setAttribute('stroke-width', strokeWidth);
  doc.appendChild(path);
}

// pass a string
function removeElement(elementId) {
  var obj = document.getElementById(elementId);
  obj.parentNode.removeChild(obj); 
}

// replace teh data attribute of an <object> tag
function updateSvgObjRoot(id, svgTag) {
  var obj = document.getElementById(id)
  obj.setAttribute('data', 'data:image/svg+xml,' + svgTag); // like <svg xmlns="http://www.w3.org/2000/svg">' + my_string + '</svg>';
}

// append element
function append_path(elementId, svgString) {
  var frag = document.createDocumentFragment(true);
  var circle = document.createElementNS(svgns, 'circle');

  circle.setAttribute('x', 10);
  circle.setAttribute('y', 10);
  circle.setAttribute('r', 5);
  circle.setAttribute('fill', 'red');

  // obj.setAttribute('data', 'data:image/svg+xml,' + svgString);

  frag.appendChild(circle)

    // svg = document.getElementById(elementId)
    // var obj = document.createElement('object', true);
    // obj.setAttribute('type', 'image/svg+xml');
    // obj.setAttribute('id', 'testid');
    // obj.setAttribute('width', '20');
    // obj.setAttribute('height', '20');
    alert('appending!');
  var svg = document.getElementsByTagNameNS(svgns, 'svg')[0];

    alert(svg);
  svg.appendChild(frag); // DocumentFragment disappears leaving circles

  // svg.appendChild(obj);
}

function toggleFigureMarkerVisibility(root_id, marker_id) {
 
  var doc = document.getElementById(root_id).contentDocument;
  var figure_marker = doc.getElementById(marker_id);
   if (figure_marker.getAttribute('opacity') === '0.55' ) {
    figure_marker.setAttribute('opacity', '0');
   } else  {
    figure_marker.setAttribute('opacity', '0.55');
  }

  // circle.setAttribute('transform',  'scale(1.4)'   ); 
 
}

function frig () { // mess with stuff
  //  var svgRoot = document.getElementById('fig_svg_root_16315').contentDocument.rootElement;

  var doc = document.getElementById('img_svg_root_16315').contentDocument;

  circle.style.fill = '#ffffff';
  circle.setAttribute('transform',  'scale(1.4)'   ); 
 
// var circle = document.getElementById('marker_587');
  // change using setAttribute
//  circle.setAttribute('fill', 'green');
  //  var svgRoot = document.getElementById('marker_587');
  // var svgRoot = currentSVGObject.contentDocument.rootElement;
  //  svgRoot.currentScale *= .95; // scale;
}

