// Author: Jack Gracie
// Version: 0.1

(function () {
  var searchString = prompt("Enter effect name to search for:", "");
  if (!searchString) {
    alert("No search string provided. Exiting.");
    return;
  }
  searchString = searchString.toLowerCase();

  var message = "";
  var numItems = app.project.numItems;
  for (var i = 1; i <= numItems; i++) {
    var item = app.project.item(i);
    if (item instanceof CompItem) {
      for (var j = 1; j <= item.numLayers; j++) {
        var layer = item.layer(j);
        if (layer.property("ADBE Effect Parade")) {
          var effects = layer.property("ADBE Effect Parade");
          for (var k = 1; k <= effects.numProperties; k++) {
            var effect = effects.property(k);
            if (effect.name.toLowerCase().indexOf(searchString) !== -1) {
              message +=
                "Comp: " +
                item.name +
                " | Layer: " +
                layer.name +
                " | Effect: " +
                effect.name +
                "\n";
            }
          }
        }
      }
    }
  }
  if (!message.length) {
    alert("Nothing Found");
  } else {
    alert("Search complete: \n" + message);
  }
})();
