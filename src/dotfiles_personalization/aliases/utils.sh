#!/bin/bash

#function move-to-storage {
#   folder=$1
#   storage=$2
#   _user=$3
#   #sudo mkdir -p $2/$1
#   #sudo chown $_user:$_user $1
#   sudo  

function mv-ln-s {
  mv "${1}" "${2}" && ln -s "${2}"/"${1}"
}

function coredumpctl-dbg-last {
  coredumpctl list
  # Get the last coredump ID (PID column, which is after the timestamp)
  local last_coredump_id=$(coredumpctl list | tail -n 1 | awk '{print $5}')
  echo "Debugging coredump ID: $last_coredump_id"
  coredumpctl debug "$last_coredump_id"
}

# Create symlinks for several files at once
function ln-s-glob {
  for file in $@; do
    ln -s "$file"
  done
}

# Make sure neovim does not override standalone vim command
function vim {
  local vimdir
  vimdir=$(ls -1d /usr/share/vim/vim* 2>/dev/null | sort -V | tail -1)
  if [[ -n "$vimdir" ]]; then
    VIMRUNTIME="$vimdir" /usr/bin/vim "$@"
  else
    /usr/bin/vim "$@"
  fi
}

grepvim() {
  local pattern="$1"
  local file="$2"
  local outfile="${file}.grep.txt"
  grep "$pattern" "$file" > "$outfile" && vim "$outfile"
}

rollbak() {
    local file=$1
    local max=5  # Number of backups to keep
    for i in $(seq $((max-1)) -1 1); do
        [ -f "$file.bak.$i" ] && mv "$file.bak.$i" "$file.bak.$((i+1))"
    done
    [ -f "$file.bak" ] && mv "$file.bak" "$file.bak.1"
    cp "$file" "$file.bak"
}

function swapf() {
    if [ $# -ne 2 ]; then
        echo "Usage: swapf file1 file2"
        return 1
    fi
    local TMPFILE=$(mktemp)
    mv "$1" "$TMPFILE"
    mv "$2" "$1"
    mv "$TMPFILE" "$2"
}
