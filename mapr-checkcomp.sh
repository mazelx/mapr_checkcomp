#!/bin/bash
# mapr-checkcomp - A script to show the relative compressed and uncompressd file sizes on a MapR filesystem.
# Chris Matta, Xavier Mazellier
# cmatta@mapr.com, xavier@dataonda.com
#
# Work on subdirectory 

# disable recursive without -r flag


set -o nounset
set -o errexit

SCRIPTNAME=$0;
RECURSIVE=0;
HUMAN_READABLE=0;
HADOOP=/usr/bin/hadoop;

# parse command args
OPTIND=1
# A POSIX variable
while getopts "rh" opt; do
    case "$opt" in
    r)  RECURSIVE=1
        ;;
    h)  HUMAN_READABLE=1
        ;;
    *)  usage
        ;;
    esac
done
shift $((OPTIND-1))
FILENAME=$1

# functions
usage () {
  echo "Usage: ${SCRIPTNAME}: [-h] [-r] <file name or directory name of MapR FS>";
  exit 1;
}

getUncompressed () {
  echo $(echo "$1" | awk '/(-|d)r/ {total = total + $8}END{print total}');
}

getCompressed () {
  blocks=$(echo "$1" | awk '/Total Disk Blocks/ {total = total + $5}END{print total}');
 echo $(($blocks * 8192));
}
  
getCompression () {
  echo $(echo "$1" | awk '/(-)r/ {print $2}' | sort -u | tr "\n" ", " | head -c-1 | sed -e 's/\bZ\b/LZ4/g' -e 's/\bz\b/Zlib/g' -e 's/\bL\b/LZf/g' -e 's/\bU\b/None/g');
}

humanReadableSize () {
  # Return the human readable size for a file size given in bytes
  suffix="octets";
  size=$1;
  if [[ $1 -ge 1024 ]]
  then
    suffix="Ko";
    size=$(echo "scale = 2; $size/1024" |bc);
  fi

  if [[ $1 -ge $((1024 * 1024)) ]]
  then
    suffix="Mo";
    size=$(echo "scale = 2; $size/1024" |bc);
  fi

  if [[ $1 -ge $((1024 * 1024 * 1024)) ]]
  then
    suffix="Go";
    size=$(echo "scale = 2; $size/1024" |bc);
  fi

  if [[ $1 -ge $((1024 * 1024 * 1024 * 1024)) ]]
  then
    suffix="To";
    size=$(echo "scale = 2; $size/1024" |bc);
  fi
  echo "$size $suffix";
}

# get files MFS full stats
filesStats=$($HADOOP fs -ls $(echo $(if [[ $RECURSIVE = 1 ]]; then echo "-R"; fi)) $FILENAME | awk '/-r/ {print $NF}' | while read i; do $HADOOP mfs -lss $i;done );

if [[ $filesStats = "" ]]
  then echo "no file found";
  exit;
fi

nbFiles=$(echo "$filesStats" | wc -l);
# get metrics from full stats
compressed=$(getCompressed "$filesStats");
uncompressed=$(getUncompressed "$filesStats");
compression=$(getCompression "$filesStats");

  echo "$FILENAME : $nbFiles files"
if [[ $HUMAN_READABLE -eq 1 ]]
  echo "Compression: $compression"
then
  echo "$(humanReadableSize $compressed) compressed";
  echo "$(humanReadableSize $uncompressed) uncompressed";
  echo "$(humanReadableSize $compressed) / $(humanReadableSize $uncompressed) (x$(echo "scale = 2; $uncompressed  / $compressed" | bc))"
else
  echo "$compressed compressed";
  echo "$uncompressed uncompressed";
  echo "$compressed / $uncompressed (x$(echo "scale = 2; $uncompressed / $compressed" | bc))"
fi


