#!/bin/bash
PWD=$PWD
trap ctrl_c INT
function ctrl_c() {
  # read -rsn1 -t 1
  exit 0
}

# kill all previous instances
kill -9 -INT $(pgrep music-player.sh | grep -v $$) &>/dev/null
kill -9 -INT $(pgrep youtube-dl) &>/dev/null
kill -9 -INT $(pgrep mplayer) &>/dev/null

cd $PWD/Musics
QUERY=$(echo $@ | sed 's/ /+/g')
RES=$(curl -s -X GET "https://www.googleapis.com/youtube/v3/search?q=${QUERY}&part=snippet&type=video&key=AIzaSyA1MaLuAPezFAxRQiK07nNZGv6Gl2MuVoQ&maxResults=50")
YT_ID=$(echo $RES | jq -r .items[0].id.videoId)

HISTORY[0]="$YT_ID"
IDX=1
MUSIC_NAME=$(echo $RES | jq -r .items[0].snippet.title)
while true; do
  RES=$(curl -s -X GET "https://www.googleapis.com/youtube/v3/search?q=${QUERY}&relatedToVideoId=${YT_ID}&part=snippet&type=video&key=AIzaSyA1MaLuAPezFAxRQiK07nNZGv6Gl2MuVoQ&maxResults=50")

  echo ""
  echo "Now playing: " $MUSIC_NAME
  echo "https://www.youtube.com/watch?v=${YT_ID}"
  echo -ne "\033]0; $MUSIC_NAME \007"

  youtube-dl -q -f bestaudio  "https://www.youtube.com/watch?v=${YT_ID}" &>/dev/null &
  for (( i = 0; i < 100; i++ )); do
    if [ ! -e *$YT_ID* ]; then
      sleep 1e-1
      continue
    fi
    sleep 5e-1
    mplayer -volume 50 -msgcolor -msglevel all=5:decaudio=-1:demux=-1:demuxer=-1:gplayer=-1:osd-menu=-1:cplayer=-1:subreader=-1:global=-1:decvideo=-1 *$YT_ID* 2>/dev/null &
    break
  done
  MPPID=$!

  SELECTEDNEXTSONG=0
  while kill -0 $MPPID &>/dev/null ; do
    read -rsn1 -t 1
    # x - exit
    # c - next song
    # v - menu
    if [ "$REPLY" = "x" ]; then
      rm $PWD/Musics/* &>/dev/null
      PROMPT_COMMAND='echo -ne "\033]0; $(pwd)\007"'
      killall -9 -INT youtube-dl &>/dev/null
      killall -9 -INT mplayer &>/dev/null
      exit 0
    fi
    if [ "$REPLY" = "c" ]; then
      killall -9 -INT mplayer &>/dev/null
    fi
    if [ "$REPLY" = "v" ]; then
      # redirect mplayer output
      printf 'p close(1)\np open("/dev/null", 1)\np close(2)\np open("/dev/null", 1)\nq\n' | gdb -p $MPPID &>/dev/null
      node "$PWD/yt-selection.js" $RES
      printf 'p close(1)\np open("/dev/pts/0", 1)\np close(2)\np open("/dev/pts/0", 1)\nq\n' | gdb -p $MPPID &>/dev/null
      MUSIC_NAME=$(cat tmp.txt | head -1)
      YT_ID=$(cat tmp.txt | tail -1)
      SELECTEDNEXTSONG=1
      killall -9 -INT youtube-dl &>/dev/null
      killall -9 -INT mplayer &>/dev/null
    fi
    if [ "$REPLY" = "b" ]; then
      # redirect mplayer output
      printf 'p close(1)\np open("/dev/null", 1)\np close(2)\np open("/dev/null", 1)\nq\n' | gdb -p $MPPID &>/dev/null
      node "$PWD/yt-selection.js" $RES
      printf 'p close(1)\np open("/dev/pts/0", 1)\np close(2)\np open("/dev/pts/0", 1)\nq\n' | gdb -p $MPPID &>/dev/null
      MUSIC_NAME=$(cat tmp.txt | head -1)
      YT_ID=$(cat tmp.txt | tail -1)
      SELECTEDNEXTSONG=1
    fi
  done

  # prepare for next song

  for (( i = 0; i < 50; i++ )); do
    if [ $SELECTEDNEXTSONG = 1 ]; then
      break
    fi
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
