#!/bin/sh
FFMPEG_LIB_PATH="./SSAudioEngine/FFmpeg/lib"
AUDIO_RESOURCES_PATH="./Resources"

FFMPEG_LIB_NAME="$FFMPEG_LIB_PATH/ffmpeglib.tar"
AUDIO_RESOURCES_NAME="$AUDIO_RESOURCES_PATH/audioresources.tar"

if [[ -f "$FFMPEG_LIB_NAME" ]]; then
    rm -f $FFMPEG_LIB_NAME
fi

if [[ ! -f "$AUDIO_RESOURCES_NAME" ]]; then
    rm -f $AUDIO_RESOURCES_NAME
fi

wget -O $FFMPEG_LIB_NAME http://image.king129.com/ffmpeglib.tar --verbose
if [[ $? = 0 ]]; then
    tar zxvf $FFMPEG_LIB_NAME -C $FFMPEG_LIB_PATH
fi

wget -O $AUDIO_RESOURCES_NAME http://image.king129.com/audioresources.tar --verbose
if [[ $? = 0 ]]; then
    tar zxvf $AUDIO_RESOURCES_NAME -C $AUDIO_RESOURCES_PATH
fi
open "./SSAudioToolBox.xcodeproj"