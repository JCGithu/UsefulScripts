// Author: Jack Gracie
// Version: 0.3
function consolidateCompsAndFootage() {
  if (!app.project) {
    alert("Please open a project first.");
    return;
  }

  var selectedComps = [];

  function collectComps(item) {
    if (item instanceof CompItem) {
      selectedComps.push(item);
    } else if (item instanceof FolderItem) {
      for (var i = 1; i <= item.numItems; i++) {
        collectComps(item.item(i));
      }
    }
  }

  for (var i = 0; i < app.project.selection.length; i++) {
    collectComps(app.project.selection[i]);
  }

  var scriptName = "Project Compactor";

  // DIALOG
  var dialog = new Window("dialog", scriptName);
  dialog.orientation = "column";
  var optionsGroup = dialog.add("panel", undefined, "Select Actions to Run:");
  optionsGroup.orientation = "column";
  var reduceOption = optionsGroup.add("checkbox", undefined, "Reduce Project");
  var consolidateFootageOption = optionsGroup.add(
    "checkbox",
    undefined,
    "Consolidate Footage"
  );
  var consolidateCompsOption = optionsGroup.add(
    "checkbox",
    undefined,
    "Consolidate Compositions"
  );
  var consolidateNullsOption = optionsGroup.add(
    "checkbox",
    undefined,
    "Consolidate Nulls & Solids"
  );
  var buttonGroup = dialog.add("group");
  buttonGroup.orientation = "row";
  var okButton = buttonGroup.add("button", undefined, "OK");
  var cancelButton = buttonGroup.add("button", undefined, "Cancel");

  // OPTIONS
  okButton.onClick = function () {
    dialog.close(1);
  };
  cancelButton.onClick = function () {
    dialog.close(0);
  };
  if (dialog.show() !== 1) {
    return;
  }
  if (reduceOption.value && selectedComps.length === 0) {
    alert("Please select at least one composition for 'Reduce Project'.");
    return;
  }

  app.beginUndoGroup(scriptName);

  var reduced = 0;
  var footage = 0;
  var comps = {
    count: 0,
    comps: [],
  };
  var nulls = 0;

  if (reduceOption.value) {
    reduced = app.project.reduceProject(selectedComps);
  }
  if (consolidateFootageOption.value) {
    footage = app.project.consolidateFootage();
  }
  if (consolidateCompsOption.value) {
    comps = consolidateCompositions();
  }
  if (consolidateNullsOption.value) {
    nulls = consolidateSolidsAndNulls();
  }
  var folders = removeEmptyFolders();

  var message = "Consolidation complete!";
  if (reduced) message += "\n\n" + "Footage reduced: " + reduced;
  if (footage) message += "\n\n" + "Footage consolidated: " + footage;
  if (comps.count)
    message += "\n\n" + "Compositions consolidated: " + comps.count;
  if (nulls) message += "\n\n" + "Nulls & Solids consolidated: " + folders;
  if (folders) message += "\n\n" + "Folders removed: " + folders;
  message += "\n";
  if (comps.comps.length) {
    message += "Duplicated comps were:\n";
    for (var i = 0; i < comps.comps.length; i++) {
      message += comps.comps[i].name + "\n";
    }
  }
  alert(message);

  app.endUndoGroup();
}

function consolidateCompositions() {
  var allComps = [];
  for (var i = 1; i <= app.project.numItems; i++) {
    if (app.project.item(i) instanceof CompItem) {
      allComps.push(app.project.item(i));
    }
  }

  var consolidated = {};
  var consolidatedCount = 0;
  var remainingComps = [];

  for (var i = 0; i < allComps.length; i++) {
    var compA = allComps[i];
    var key =
      compA.name +
      "|" +
      compA.width +
      "|" +
      compA.height +
      "|" +
      compA.frameRate +
      "|" +
      compA.duration;
    if (consolidated[key]) {
      for (var j = 1; j <= app.project.numItems; j++) {
        var item = app.project.item(j);
        if (item instanceof CompItem) {
          for (var k = 1; k <= item.numLayers; k++) {
            var layer = item.layer(k);
            if (layer.source === compA) {
              layer.replaceSource(consolidated[key], true);
            }
          }
        }
      }
      compA.remove();
      consolidatedCount++;
      if (!arrayContains(remainingComps, consolidated[key])) {
        remainingComps.push(consolidated[key]);
      }
    } else {
      consolidated[key] = compA;
    }
  }

  return {
    count: consolidatedCount,
    comps: remainingComps,
  };
}

function removeEmptyFolders() {
  var removedCount = 0;
  for (var i = app.project.numItems; i >= 1; i--) {
    var item = app.project.item(i);
    if (item instanceof FolderItem) {
      var isEmpty = true;
      for (var j = 1; j <= app.project.numItems; j++) {
        if (app.project.item(j).parentFolder === item) {
          isEmpty = false;
          break;
        }
      }
      if (isEmpty) {
        item.remove();
        removedCount++;
      }
    }
  }
  return removedCount;
}

function consolidateSolidsAndNulls() {
  var consolidatedSolids = {}; // To track unique solids
  var consolidatedNulls = {}; // To track unique nulls
  var consolidatedSolidCount = 0;
  var consolidatedNullCount = 0;

  for (var i = 1; i <= app.project.numItems; i++) {
    var item = app.project.item(i);
    if (item instanceof CompItem) {
      for (var j = 1; j <= item.numLayers; j++) {
        var layer = item.layer(j);
        if (layer instanceof AVLayer) {
          // Consolidate Solids
          if (layer.source.mainSource instanceof SolidSource) {
            var solidKey =
              "Solid|" +
              layer.source.mainSource.color.toString() +
              "|" +
              layer.source.width +
              "|" +
              layer.source.height +
              "|" +
              layer.source.pixelAspect;
            if (consolidatedSolids[solidKey]) {
              layer.replaceSource(consolidatedSolids[solidKey], false);
              consolidatedSolidCount++;
            } else {
              consolidatedSolids[solidKey] = layer.source;
            }
          }

          // Consolidate Nulls
          if (layer.nullLayer) {
            var nullKey = "Null|" + layer.width + "|" + layer.height;
            if (consolidatedNulls[nullKey]) {
              layer.replaceSource(consolidatedNulls[nullKey], false);
              consolidatedNullCount++;
            } else {
              consolidatedNulls[nullKey] = layer.source;
            }
          }
        }
      }
    }
  }

  for (var i = app.project.numItems; i >= 1; i--) {
    curItem = app.project.item(i);
    if (
      app.project.item(i).mainSource instanceof SolidSource &&
      app.project.item(i).usedIn.length == 0
    ) {
      app.project.item(i).remove();
    }
  }

  return consolidatedNullCount + consolidatedSolidCount;
}

function arrayContains(arr, value) {
  for (var i = 0; i < arr.length; i++) {
    if (arr[i] === value) {
      return true;
    }
  }
  return false;
}

consolidateCompsAndFootage();
