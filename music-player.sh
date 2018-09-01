#!/bin/bash

trap ctrl_c INT
function ctrl_c() {
  if [ "$EXIT" = 1 ]; then
    rm ~/Music/* 2>/dev/null
    PROMPT_COMMAND='echo -ne "\033]0; $(pwd)\007"'
    exit 0
  fi
  EXIT=$(( $EXIT + 1 ))
}

# kill all previous instances
kill -9 $(pgrep music-player.sh | grep -v $$) 2>/dev/null
kill -9 $(pgrep youtube-dl) 2>/dev/null
kill -9 $(pgrep mplayer) 2>/dev/null


PWD=$(pwd)
cd ~/Music
QUERY=$(echo $@ | sed 's/ /+/g')
RES=$(curl -s -X GET "https://www.googleapis.com/youtube/v3/search?q=${QUERY}&part=snippet&type=video&key=AIzaSyA1MaLuAPezFAxRQiK07nNZGv6Gl2MuVoQ")
YT_ID=$(echo $RES | jq -r .items[0].id.videoId)

HISTORY[0]="$YT_ID"
IDX=1
MUSIC_NAME=$(echo $RES | jq -r .items[0].snippet.title)
while true; do

  echo ""
  echo "Now playing: " $MUSIC_NAME
  echo "https://www.youtube.com/watch?v=${YT_ID}"
  echo -ne "\033]0; $MUSIC_NAME \007"

  EXIT=0
  youtube-dl -q -f bestaudio  "https://www.youtube.com/watch?v=${YT_ID}" &
  for (( i = 0; i < 100; i++ )); do
    if [ ! -e *$YT_ID* ]; then
      sleep 1e-1
      continue
    fi
    sleep 5e-1
    mplayer -volume 50 -msgcolor -msglevel all=5:decaudio=-1:demux=-1:demuxer=-1:gplayer=-1:osd-menu=-1:cplayer=-1:subreader=-1:global=-1:decvideo=-1 *$YT_ID* 2>/dev/null
    break
  done

  # prepare for next song
  RES=$(curl -s -X GET "https://www.googleapis.com/youtube/v3/search?q=${QUERY}&relatedToVideoId=${YT_ID}&part=snippet&type=video&key=AIzaSyA1MaLuAPezFAxRQiK07nNZGv6Gl2MuVoQ&maxResults=50")


  for (( i = 0; i < 50; i++ )); do
    END="0"
    YT_ID=$(echo $RES | jq -r .items[$i].id.videoId)
    MUSIC_NAME=$(echo $RES | jq -r .items[$i].snippet.title)
    for (( j = 0; j < 50; j++ )); do
      if [[ "$YT_ID" = ${HISTORY[j]} ]]; then
        END="1"
        break
      fi
    done
    if [[ $END = "0" ]]; then
      HISTORY[$IDX]="$YT_ID"
      IDX=$(( $IDX + 1 ))
      IDX=$(( $IDX % 50 ))
      break
    fi
  done

done
