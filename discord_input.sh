# <one line to give the program's name and a brief idea of what it does.>
# Copyright (C) 2021  Vidhu Kant Sharma
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

#!/usr/bin/env bash

switch_discord_input=ask # ask|yes|no
sink_name=merged_streams
sink_description=""

while getopts 'n:s:N:S' flag; do
  case "${flag}" in
    n) no_of_streams="${OPTARG}" ;;
    s) switch_discord_input="${OPTARG}" ;;
    N) sink_name="${OPTARG}" ;;
    D) sink_description="${OPTARG}" ;;
    *) ;;
  esac
done

if [ "$sink_description" == "" ]; then
  sink_description="$sink_name"
fi

# get the amount of streams to merge if not specified
if [ "$no_of_streams" = "" ]; then
  printf "\033[1;36mEnter number of sinks/sources to merge: \033[0m"
  read -r no_of_streams
fi

# create NULL sink to merge all the audio streams
pacmd load-module module-null-sink sink_name="$sink_name"

# change desc of NULL sink and it's monitor for visual purpose
pacmd update-sink-proplist "$sink_name" device.description="$sink_description"
pacmd update-source-proplist "$sink_name.monitor" device.description="\"Monitor of $sink_name\""

i=0; while [ $i -lt "$no_of_streams" ]; do
  # get sources and split
  SAVEIFS=$IFS
  IFS=$'\n'
  # somebody help
  sources=($(pacmd list-sources | awk '/name:/ {print $2}; /device.description/ {$1=$2=""; print $0}' | sed 's/^[ \t\"]*//; s/[ \t\"]$//' | awk 'NR%2==0 {printf "\033[34m"$0"\t \033[0;32m"f"\033[0m\n"}  {f=$0}'))
  IFS=$SAVEIFS

  # print all the sources with their indices
  for (( j=0; j<${#sources[@]}; j++ )); do
    unformatted_sink_name="$(echo "${sources[j]}" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')"
    new_sink_name="Monitor of $sink_name	 <$sink_name.monitor>"

    # do not print the newly created NULL output's monitor
    if [ "$unformatted_sink_name" != "$new_sink_name" ]; then
      printf "\033[1;33m%s: %s\n" "$j" "${sources[$j]}"
    fi
  done

  # ask to enter source number
  printf "\033[1;36mEnter a value: \033[0m"
  read -r source_idx

  # extract source name and save it
  source_sel=$(echo "${sources[source_idx]}" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' | awk -F "\t" '{print $2}' | sed 's/^[ <]*//; s/>$//')

  # finally create loopback
  pacmd load-module module-loopback sink="$sink_name" source="$source_sel"

  # get new loopback's index and rename loopback
  loopback_idx=$(pacmd list-source-outputs | egrep '(.*index: .*)|(^\s+media.name = .*)' | awk "/Loopback to $sink_name/ {printf f} {f=\$2}")
  pacmd update-source-output-proplist "$loopback_idx" media.name="\"Merged stream #$((i+1))\""

  i=$((i + 1))
done

# check if switching disabled through flags
if [ "$switch_discord_input" != no ]; then
  # get index of discord's source output
  discord_idx="$(pacmd list-source-outputs | egrep '(.*index: .*)|(^\s+application.process.binary = .*)' | awk '/Discord/ {printf f} {f=$2}')"
  
  # ask the user and change discord's input to new input
  if [ "$discord_idx" == "" ]; then
    printf "\033[1;31mDiscord instance not found/recording. If it is running, please use Discord settings or pavucontrol to manually change its input.\033[0m\n"
  else
    if [ "$switch_discord_input" == ask ]; then
      printf "\033[1;36mDiscord is running, switch discord's input to new merged input?(y/n)\033[0m "

      # get response
      while :; do
        read -r response
  
        if [ "$response" == y ] || [ "$response" == Y ]; then
          echo did it
          pacmd move-source-output "$discord_idx" "$sink_name.monitor"
          break
        elif [ "$response" == n ] || [ "$response" == N ]; then
          break
        else 
          printf "\033[1;36mPlease enter a valid input (y/n):\033[0m "
        fi
      done
    else
      echo did it
      pacmd move-source-output "$discord_idx" "$sink_name.monitor"
    fi
  fi
fi


