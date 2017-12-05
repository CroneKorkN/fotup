#!/bin/bash

#sudo apt install exfat-fuse exfat-utils exiftool
# TODO check if file really is a multimedia file

SDPATH="/media/pi/EOS_DIGITAL"
CACHEPATH=~/fotup_cache
SORTEDPATH=~/fotup_sorted
EXIFCACHE=/tmp/fotup_exifcache
REMOTEHOST=ckn@10.0.0.1
REMOTEPATH=/var/lib/nextcloud/ckn/files/Bilder/Unsortiert

mkdir -p "$CACHEPATH" "SORTEDPATH"
while true; do
  if [[ -d "$SDPATH" ]]; then
    echo "caching..."
    # copy all raw, jpg and movie to cachepath and flatten directory structure
    rsync -Pavz "$SDPATH" "$CACHEPATH"
    echo "done caching. sorting..."
    for f in $(find "$CACHEPATH" -regex "[^.]*\.\(JPG\|CR2\|MP4\)"); do
      exiftool "$f" > "$EXIFCACHE"
      if cat "$EXIFCACHE" | grep -m 1 "EOS 80D"; then CAM="80D"; else CAM="550D"; fi
      NUM=$(basename $f | cut -d'_' -f2 | cut -d'.' -f1)
      HASH=$(echo "$CAM$NUM" | shasum | head -c 5)
      YEAR=$(cat "$EXIFCACHE" | grep -m 1 "Create Date" | cut -d':' -f2 | tr -d " \t")
      MONTH=$(cat "$EXIFCACHE" | grep -m 1 "Create Date" | cut -d':' -f3)
      DAY=$(cat "$EXIFCACHE" | grep -m 1 "Create Date" | cut -d':' -f4 | cut -d' ' -f1)
      HOUR=$(cat "$EXIFCACHE" | grep -m 1 "Create Date" | cut -d':' -f4 | cut -d' ' -f2)
      MINUTE=$(cat "$EXIFCACHE" | grep -m 1 "Create Date" | cut -d':' -f5)
      SECOND=$(cat "$EXIFCACHE" | grep -m 1 "Create Date" | cut -d':' -f6)
      EXT=$(basename $f | cut -d'.' -f2 | tr '[:upper:]' '[:lower:])
      if [[ "$EXT" = "CR2" ]]; then RAW="raw/"; else RAW=""; fi
      TARGETPATH="$SORTEDPATH/$YEAR/$MONTH/$DAY/$RAW$YEAR$MONTH$DAY"-"$HOUR$MINUTE$SECOND"-"$HASH"."$EXT"
      mkdir -p "$(dirname "$TARGETPATH")"
      mv -v "$f" "$TARGETPATH"
    done
    echo "done sorting. uploading..."
  fi
  sleep 10000
done

