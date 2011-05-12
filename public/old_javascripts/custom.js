// [RAILSROOT]/public/javascripts/custom.js

/** 
 * Updates an arbitrary number of targets with new HTML
 * 
 * @fragments  object  an object containing properties that map
 *                     fragment identifiers to HTML element IDs
 * @xml        string  the XML text that contains the fragment
 *                     identifiers and replacement HTML
 */
function updatesFromXML(fragments, xml) {
  for(fragment in fragments) {
    var matches = new RegExp("<" + fragment + 
    "><!\\[CDATA\\[([\\s\\S]*)\\]\\]></" + fragment + 
    ">").exec(xml);
    if(matches) {
      $(fragments[fragment]).innerHTML = matches[1];
    }
  }
}

