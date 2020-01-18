#!/bin/bash

#License: GPL 2.0 <https://www.gnu.org/licenses/gpl-2.0.txt>

set -e

# do not change this
DISPLAY_BAK=$DISPLAY

# 2160p: 3840x2160
# 1440p: 2560x1440
# 1080p: 1920x1080
# 720p: 1280x720
# 480p: 854x480
# 360p: 640x360
# 240p: 426x240
if [ -z "$DIPLAY_SIZE" ]; then
    # HD
    DISPLAY_SIZE=1280x720
fi
AUDIO_OPTION="-codec:a aac"
#QUICKTIME_OPTION="-pix_fmt yuv420p"
QUICKTIME_OPTION=
DEPTH=24

LIMIT=0
PAUSE=1
TEST=0

# do not change this
DISPLAY_NUM=99
SCREEN=0

# TODO command arg
OUTPUT_DIR="./output"
SC=0

CMD="$*"

#CMD_BIN=$(basename "$CMD" )
CMD_BIN=$(echo $CMD | awk '{print $1}' | xargs basename)

AUTH_ERR_LOG="./error.log"
VIDEO_OUTFILE="${CMD_BIN}.mp4"
IMAGE_OUTFILE="${CMD_BIN}.png"
TMP="/tmp/${RANDOM}"

if [ ! -d $OUTPUT_DIR ]; then
    mkdir $OUTPUT_DIR
fi

(rm "$AUTH_ERR_LOG" || true) 2>/dev/null
(rm "$OUTPUT_DIR/$VIDEO_OUTFILE" || true) 2>/dev/null
(rm "$OUTPUT_DIR/$IMAGE_OUTFILE" || true) 2>/dev/null

while [[ $(pidof Xvfb) ]]; do
    #echo "Instance of Xvfb already running. Behaviour undefined. Exiting."
    #exit 1
    echo "[*] Killing previous Xvfb instance"
    killall Xvfb || true
done

function make_screenshot(){
    if [ $SC = 0 ]; then
        sleep 1
    fi
    SC=$((SC + 1))
    echo "[*] Making Screenshot $SC"
    (xwd -display :$DISPLAY_NUM -root -out "${TMP}.xwd" >/dev/null && 
        convert "${TMP}.xwd" "${OUTPUT_DIR}/${SC}_${IMAGE_OUTFILE}") || true
}

echo "[*] Starting xvfb-run"
(xvfb-run --error-file $AUTH_ERR_LOG --server-args=":${DISPLAY_NUM} -auth /tmp/xvfb.auth -ac -screen ${SCREEN} ${DISPLAY_SIZE}x${DEPTH}" ${CMD} >/dev/null) & disown
cmdpid=$!

echo "[*] Recording"
(ffmpeg $AUDIO_OPTION $QUICKTIME_OPTION -f x11grab -s $DISPLAY_SIZE -i :$DISPLAY_NUM -y "$OUTPUT_DIR/$VIDEO_OUTFILE" &> $OUTPUT_DIR/movie_log.txt) & disown
recpid=$!

while true; do
    make_screenshot
    sleep $PAUSE
    # kill the recording after $limit iterations
    if [[ ($SC -ge $LIMIT)  && ($LIMIT -ne 0) ]]; then
        (kill "$recpid" >/dev/null) || true
    elif [[ $TEST -eq 1 ]]; then
        # kill the *window* (Hello World" after one iteration via xdotool
        # windowkill this just means that if the application exits, xvfb shuts down
        # and the recording stops
        export DISPLAY=:${DISPLAY_NUM}
        WID=$(xdotool search --name "Hello" | head -1)
        xdotool windowkill "$WID"
        export DISPLAY=${DISPLAY_BAK}
    fi
    (ps -p "$cmdpid" >/dev/null) || break
done

while true; do
    kill "$recpid" 2>/dev/null || true
    sleep $PAUSE
    (ps -p "$recpid" >/dev/null) || break
done
(killall Xvfb 2>/dev/null || true)

echo "[*] Finished cleanly"
exit 0
