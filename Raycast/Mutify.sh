#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Mutify
# @raycast.mode inline

# Optional parameters:
# @raycast.icon 🎧
# @raycast.currentDirectoryPath ~
# @raycast.needsConfirmation false

# Documentation:
# @raycast.description Runs a script to mute Spotify ads

set -e

if [ -z $(pgrep -x Spotify) ]; then
    echo
    echo "✋ Spotify is not running. Please launch Spotify App first"
    echo
    exit
fi

IS_SCRIPT_RUNNING=$(ps aux|grep -c "[M]utify.sh")
if [ $IS_SCRIPT_RUNNING -gt 2 ]; then
    echo "The script is already running. Automatically closing it..."
    echo
    echo "Please re-launch the script now"
    PID=$(ps -eo pid,lstart,command | grep "[M]utify.sh" | sort -k 2 | awk '{print $1}')
    kill -9 ${PID}
    exit
fi

rendertimer(){
    # convert seconds to Days, Hours, Minutes, Seconds
    # thanks to Nikolay Sidorov and https://www.shellscript.sh/tips/hms/
    local parts seconds D H M S D_TAG H_TAG M_TAG S_TAG
    seconds=${1:-0}
    # all days
    D=$((seconds / 60 / 60 / 24))
    # all hours
    H=$((seconds / 60 / 60))
    H=$((H % 24))
    # all minutes
    M=$((seconds / 60))
    M=$((M % 60))
    # all seconds
    S=$((seconds % 60))

    # set up "x day(s), x hour(s), x minute(s) and x second(s)" language
    [ "$D" -eq "1" ] && D_TAG="day" || D_TAG="days"
    [ "$H" -eq "1" ] && H_TAG="hour" || H_TAG="hours"
    [ "$M" -eq "1" ] && M_TAG="min" || M_TAG="mins"
    [ "$S" -eq "1" ] && S_TAG="sec" || S_TAG="secs"

    # put parts from above that exist into an array for sentence formatting
    parts=()
    [ "$D" -gt "0" ] && parts+=("$D $D_TAG")
    [ "$H" -gt "0" ] && parts+=("$H $H_TAG")
    [ "$M" -gt "0" ] && parts+=("$M $M_TAG")
    [ "$S" -gt "0" ] && parts+=("$S $S_TAG")

    # construct the sentence
    result=">> ⏳ "
    lengthofparts=${#parts[@]}
    for (( currentpart = 0; currentpart < lengthofparts; currentpart++ )); do
        result+="${parts[$currentpart]}"
        # if current part is not the last portion of the sentence, append a comma
        [ $currentpart -ne $((lengthofparts-1)) ] && result+=", "
    done
    echo "$result of ads silenced so far 😎"
    echo
}

# create stats file
# this file stores the amount of seconds of ads blocked by the script
STATS_PATH="/Users/jgracie/Documents/Personal/Misc"
STATS_FILENAME="stats.txt"
STATS_FULLPATH=$(echo $STATS_PATH"/"$STATS_FILENAME | tr -s /)
if ! test -f $STATS_FULLPATH; then
    echo 0 > $STATS_FULLPATH
fi

# How many seconds before checking if and ad is playing.
# Setting this to a lower value will increase CPU usage
INTERVAL_CHECK_TIME_SEC=0.5

# Set vars to prevent double print on alerts
MSG_AD_ECHOED=0
MSG_SONG_PLAYING_ECHOED=0

CURRENT_VOLUME=$(osascript -e 'tell application "Spotify" to set A to sound volume')

echo
echo "Spotify Ads will be silenced while this program is running! (This works ONLY with the Spotify App, not the web version)"
echo "This program was downloaded from https://gdi3d.github.io/mute-spotify-ads-mac-osx/ (check for documentation)"
echo
echo "If the program is not working properly please open an issue at: https://github.com/gdi3d/mute-spotify-ads-mac-osx/issues/new"
echo
echo "Press control+c to close this program or close the terminal window"
echo

while :
    do 

        # Thanks to @bbbco for this cool tip on how to use 
        # osascript to get the current track url
        AD_DETECTED=$(osascript -e 'tell application "Spotify" to get spotify url of current track'|cut -d ":" -f 2)
        
        # prevent 'if unary operator expected' error
        # in case spotify is closed
        if [ -z $AD_DETECTED ]; then
            sleep 5
            continue
        fi

        if [ $AD_DETECTED == 'ad' ]; then

            if [ $MSG_AD_ECHOED -eq 0 ]; then
                
                # Ad found! Lower volume
                osascript -e 'tell application "Spotify" to set sound volume to 1'

                MSG_AD_ECHOED=1
                
                echo ">> 🔇 Ad found! Your volume will be set all the way down now until the next song!"
                osascript -e "display notification \"🔇 Ad found! Your volume will be set all the way down now until the next song!\" with title \"Muting Spotify Ad\""

                # start counting. This will be added to the stats.txt file later on
                AD_TIME_START=$(date +%s)
            fi

            MSG_SONG_PLAYING_ECHOED=0

        else

            if [ $MSG_SONG_PLAYING_ECHOED -eq 0 ]; then
                    
                # Ad is gone. Restore volume!
                osascript -e 'tell application "Spotify" to set sound volume to '$(($CURRENT_VOLUME+1))

                MSG_SONG_PLAYING_ECHOED=1
                echo ">> 🔈 Songs are playing 😀🕺💃. Audio back to normal"
                
                # add seconds to stats file
                if ! [ -z $AD_TIME_START ]; then 
                    AD_TIME_END=$(date +%s)
                    AD_ELAPSED_TIME=$(($AD_TIME_END-$AD_TIME_START))
                    echo $(($(cat $STATS_FULLPATH)+$AD_ELAPSED_TIME)) > $STATS_FULLPATH
                    SILENCE_STATS=$(cat $STATS_FULLPATH)
                    rendertimer $SILENCE_STATS

                    if [ $SHOW_SYSTEM_NOTIFICATIONS -eq 1 ]; then
                        STAT_NOT=$(rendertimer $SILENCE_STATS)
                        osascript -e "display notification \"$STAT_NOT\" with title \"Songs are playing 😀🕺💃\""
                    fi
                fi
            fi
            
            CURRENT_VOLUME=$(osascript -e 'tell application "Spotify" to set A to sound volume')
            MSG_AD_ECHOED=0

        fi

        # Wait before check again
        sleep $INTERVAL_CHECK_TIME_SEC
    done

# echo an error message before exiting on error
trap 'echo ">>> ⛔️ 👎 Oops! Something failed and the program is not running. Please open a new issue at: https://github.com/gdi3d/mute-spotify-ads-mac-osx/issues/new and copy and paste the whole output of this window into so I can fix it."' EXIT