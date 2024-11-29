#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Shutdown Timer
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ⏱️
# @raycast.argument1 { "type": "text", "placeholder": "Minutes" }
# @raycast.argument2 { "type": "text", "placeholder": "Hours", "optional": true}

# Documentation:
# @raycast.description Shutdown Timer 
# @raycast.author Jack

# How to get this to work:
# You need to remove the need for a password to run the shutdown command
# Get into the customisation file by typing this in the terminal `sudo visudo /etc/sudoers.d/customisations`
# Then add this line, with [user] replaced with your user ID `user ALL=NOPASSWD: /sbin/shutdown`
# You will need to know/google the basics of Vim to input/save that.

minutes="$1"

if [ -z "$2" ]; then
  hours="0"
else
  hours="$2"
fi

# Convert the minutes and hours to integers
minutes=$((minutes + 0))
hours=$((hours + 0))

# Multiply the hours by 60 to get minutes
hours_in_minutes=$((hours * 60))

# Add the hours in minutes to the minutes
total_minutes=$((minutes + hours_in_minutes))

# Provide feedback
echo "Shutdown in $total_minutes minutes"
osascript -e "display notification \"⏱️ Mac will shutdown in $total_minutes minutes\" with title \"Shut Down: $total_minutes\ mins\" sound name \"Funky\""
sudo shutdown -h +$total_minutes
