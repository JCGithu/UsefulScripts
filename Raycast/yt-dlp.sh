#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title YT-DLP
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "Video URL" }
# @raycast.argument2 { "type": "dropdown", "placeholder": "Specific Format", "data": [{"title": "Any", "value": ""}, {"title": "MP4", "value": "--recode-video mp4 "}, {"title": "MP3", "value": "--recode-video mp3"}]  }

# Documentation:
# @raycast.description Download with YT-DLP
# @raycast.author Jack

(cd /Users/jgracie/Downloads/YT-DLP; yt-dlp $2 $1)
