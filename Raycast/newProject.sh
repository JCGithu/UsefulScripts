#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New Project
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📁
# @raycast.packageName File Operations
# @raycast.argument1 { "type": "text", "placeholder": "New Folder Name" }

SOURCE_DIR=""
DEST_DIR=""

mkdir -p "$DEST_DIR"

NEW_FOLDER_NAME="$1"

cp -R "$SOURCE_DIR" "$DEST_DIR/$NEW_FOLDER_NAME"

# This section is only needed for defining and renaming specific files within the new folder
AFX_FILE="$DEST_DIR/$NEW_FOLDER_NAME/_PROJECT_FILES/AFX/AFX_TEMPLATE_2021.aep"
PRM_FILE="$DEST_DIR/$NEW_FOLDER_NAME/_PROJECT_FILES/PRM/PREMIERE_PRO_2024_TEMPLATE.prproj"
mv "$AFX_FILE" "$DEST_DIR/$NEW_FOLDER_NAME/_PROJECT_FILES/AFX/${NEW_FOLDER_NAME}_V1.aep"
mv "$PRM_FILE" "$DEST_DIR/$NEW_FOLDER_NAME/_PROJECT_FILES/PRM/${NEW_FOLDER_NAME}_V1.prproj"

open "$DEST_DIR/$NEW_FOLDER_NAME"
echo "Folder copied, renamed to $DEST_DIR/$NEW_FOLDER_NAME, files renamed, and opened in Finder"