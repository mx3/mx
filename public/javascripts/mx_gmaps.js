//var centerLatitude = 37.4419;
//var centerLongitude = -122.1419;
//var startZoom = 12;

var map;

function init() {
  if (GBrowserIsCompatible()) {
    map = new GMap2(document.getElementById("map"));
    map.addControl(new GSmallMapControl());
    map.addControl(new GMapTypeControl());
    map.setCenter(new GLatLng(centerLatitude, centerLongitude), startZoom);
  //  listMarkers();

    GEvent.addListener(map, "click", function(overlay, latlng) {
      if (overlay == null) {
        //create an HTML DOM form element
        var inputForm = document.createElement("form");
        inputForm.setAttribute("action","");
        inputForm.id='add-ce-input'
        inputForm.onsubmit = function() {storeMarker(); return false;};
        
        //retrieve the longitude and lattitude of the click point
        var lng = latlng.lng();
        var lat = latlng.lat();
  
        inputForm.innerHTML = '<fieldset style="width:420px;">'
            + '<legend>New Collecting Event</legend>'     
            + '<div class="fr"><label for="ce_verbatim_label" class="lbl4">Verbatim Label</label><span class="fld"><textarea rows="6" style="width: 100%;" id="verbatim_label" name="m[verbatim_label]" /></textarea></span></div>' 
            + '<div class="fr"><label for="ce_notes" class="lbl4">Notes</label><span class="fld"><textarea rows="4" style="width: 100%;" id="notes" name="m[notes]" /></textarea></span></div>'
            + '<div class="fr"><label for="ce_num_to_print" class="lbl4"># to print</label><span class="fld"><input type="text" id="num_to_print" name="m[lnum_to_print]" size="4" /></span></div>'
            + '<div class="fr"><label for="none" class="lbl4"></label><span class="fld"><input type="submit" value="Save"/></span></div>'            
            + '<input type="hidden" id="longitude" name="longitude" value="' + lng + '"/>'
            + '<input type="hidden" id="latitude" name="latitude" value="' + lat + '"/>'
            + '</fieldset>';
  
        map.openInfoWindow (latlng,inputForm);
      }
    });
  }
}

function storeMarker(){
    var lng = document.getElementById("longitude").value;
    var lat = document.getElementById("latitude").value;
    var notes = document.getElementById("notes").value;
    var verbatim_label = document.getElementById("verbatim_label").value;
    var num_to_print = document.getElementById("num_to_print").value;

    var getVars =  "?m[longitude]=" + lng
        + "&m[latitude]=" + lat 
        + "&m[notes]=" + notes 
        + "&m[verbatim_label]=" + verbatim_label
        + "&m[num_to_print]=" + num_to_print

    var request = GXmlHttp.create();

    //call the store_marker action back on the server
    request.open('GET', 'create_from_gmap' + getVars, true);
    request.onreadystatechange = function() {
        if (request.readyState == 4) {
            //the request is complete

            var success=false;
            var content='Error contacting web service';
            try {
              //parse the result to JSON (simply by eval-ing it)
              res=eval( "(" + request.responseText + ")" );
              content=res.content;
              success=res.success;              
            }catch (e){
              success=false;
            }

            //check to see if it was an error or success
            if(!success) {
                alert(content);
            } else {
                //create a new marker and add its info window
                var latlng = new GLatLng(parseFloat(lat),parseFloat(lng));
                var marker = createMarker(latlng, content);
                map.addOverlay(marker);
                map.closeInfoWindow();
            }
        }
    }
    request.send(null);
    return false;
}

function createMarker(latlng, html) {
     var marker = new GMarker(latlng);
     GEvent.addListener(marker, 'click', function() {
          var markerHTML = html;
          marker.openInfoWindowHtml(markerHTML);
    });
    return marker;
}

function listMarkers() {
  var request = GXmlHttp.create();
  //tell the request where to retrieve data from.
  request.open('GET', 'list', true);
  //tell the request what to do when the state changes.
  request.onreadystatechange = function() {
    if (request.readyState == 4) {
      //parse the result to JSON,by eval-ing it.
      //The response is an array of markers
      markers=eval( "(" + request.responseText + ")" );
      for (var i = 0 ; i < markers.length ; i++) {
        var marker=markers[i].attributes
        var lat=marker.lat;
        var lng=marker.lng;
        //check for lat and lng so MSIE does not error
        //on parseFloat of a null value
        if (lat && lng) {
        var latlng = new GLatLng(parseFloat(lat),parseFloat(lng));
        var html = '<div><b>Found</b> ' + marker.found + '</div><div><b>Left</b> '
                  + marker.left + '</div>';
        var marker = createMarker(latlng, html);
        map.addOverlay(marker);
        } // end of if lat and lng
      } // end of for loop
    } //if
  } //function
  request.send(null);
}

function init_point() {
  if (GBrowserIsCompatible()) {
    map = new GMap2(document.getElementById("map"));
    map.addControl(new GSmallMapControl());
    map.addControl(new GMapTypeControl());
    map.setCenter(new GLatLng(centerLatitude, centerLongitude), startZoom);

    var location = new GLatLng(centerLatitude, centerLongitude);
    var marker = new GMarker(location);
    map.addOverlay(marker);
  }
}


function init_map() {
  if (GBrowserIsCompatible()) {
    map = new GMap2(document.getElementById("map"));
    map.addControl(new GSmallMapControl());
    map.addControl(new GMapTypeControl());
    
    map.setCenter(new GLatLng(centerLatitude, centerLongitude), startZoom);

    for(i=0; i<markers.length; i++) {
        addMarker(markers[i].latitude, markers[i].longitude, markers[i].name);
    }

  }
}

function addMarker(latitude, longitude, description) {
  var marker = new GMarker(new GLatLng(latitude, longitude));
  GEvent.addListener(marker, 'click',
      function() {
        marker.openInfoWindowHtml(description);
      }
      );
    map.addOverlay(marker);
}


// window.onload = init;
// window.onunload = GUnload;

