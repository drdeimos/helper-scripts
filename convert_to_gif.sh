#!/bin/bash

# Author: Mikhail Nosov (drdeimosnn@gmail.com)
# Convert video to HQ gif
# convert_to_gif.sh <source_video> <destination_gif> <start_time> <duration>
# Example usage:
# convert_to_gif.sh source_video.mp4 out_animation.gif "00:00:14" "00:00:10"

INFILE=${1}
OUTFILE=${2}
PALETE="/tmp/$(makepasswd --chars=20).png"
STARTPOS=${3:-"00:00:00"}
DURATION=${4:-"NONE"}
FPS=15
#SCALE=",scale=400:-1"
SCALE=",scale=-1:-1"

function convert {
  INFILE=${1}
  if [ ${DURATION} != "NONE" ];then
    ffmpeg -ss ${STARTPOS} -t ${DURATION} -i "${INFILE}" -vf \
      fps=${FPS}${SCALE}:flags=lanczos,palettegen ${PALETE}
    ffmpeg -ss ${STARTPOS} -t ${DURATION} -i "${INFILE}" -i ${PALETE} \
      -filter_complex "fps=${FPS}${SCALE}:flags=lanczos[x];[x][1:v]paletteuse" "${OUTFILE}"
  else
    ffmpeg -ss ${STARTPOS} -i "${INFILE}" -vf \
      fps=${FPS}${SCALE}:flags=lanczos,palettegen ${PALETE}
    ffmpeg -ss ${STARTPOS} -i "${INFILE}" -i ${PALETE} \
      -filter_complex "fps=${FPS}${SCALE}:flags=lanczos[x];[x][1:v]paletteuse" "${OUTFILE}"
  fi
}


if [ $# -gt 1 ];then
  convert "${INFILE}"
else
  echo $#
  echo "Usage: $0 <input_file> <output_file>"
  exit
fi

echo "Output file: ${OUTFILE}"
rm -v ${PALETE}
