#!/bin/bash

find /usr/local/es/livestream/hls/ -type f -name "*.ts" -cmin +10 -delete
find /usr/local/es/livestream/hls/ -type f -name "*.m3u8" -cmin +10 -delete
find /usr/local/es/livestream/dash/ -type f -name "*.mp4" -cmin +10 -delete
find /usr/local/es/livestream/dash/ -type f -name "*.mpd" -cmin +10 -delete
