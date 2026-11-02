#!/bin/sh
# Rebuilds the two universal (Apple Silicon + Intel) binaries from source.
set -e
cd "$(dirname "$0")"
for t in edit-player photos-sync; do
  extra=""; [ $t = photos-sync ] && extra="-Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker Info.plist"
  swiftc -O -target arm64-apple-macos13 $t.swift -o $t-arm $extra
  swiftc -O -target x86_64-apple-macos13 $t.swift -o $t-x86 $extra
  lipo -create $t-arm $t-x86 -output $t && rm $t-arm $t-x86
  codesign -s - -f $t
done
