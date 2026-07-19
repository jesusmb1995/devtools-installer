#!/bin/sh
# Set st pastel 16-color palette via OSC 4 escape sequences
# (st is built without Xresources support, so this is the only way)
printf '\033]4;0;#1e2122\007'
printf '\033]4;1;#FF4486\007'
printf '\033]4;2;#95C7AE\007'
printf '\033]4;3;#F7FF7E\007'
printf '\033]4;4;#AE95C7\007'
printf '\033]4;5;#C795AE\007'
printf '\033]4;6;#95AEC7\007'
printf '\033]4;7;#FFE7AF\007'
printf '\033]4;8;#747C84\007'
printf '\033]4;9;#FF4486\007'
printf '\033]4;10;#95C7AE\007'
printf '\033]4;11;#F7FF7E\007'
printf '\033]4;12;#AE95C7\007'
printf '\033]4;13;#C795AE\007'
printf '\033]4;14;#95AEC7\007'
printf '\033]4;15;#FFF2D4\007'
# Ensure a UTF-8 locale for whatever we exec (btop/ncdu/nnn launched from
# rofi don't inherit the interactive zsh env where LANG is set).
[ -z "$LANG" ] && export LANG=C.UTF-8
[ -z "$LC_ALL" ] && export LC_ALL=C.UTF-8
# Default foreground/background
printf '\033]10;#FFE7AF\007'
printf '\033]11;#1e2122\007'
exec "$@"
