#!/bin/sh
# Builds Horloge Républicaine.app into build/. No Xcode project needed,
# just the command line tools.
set -e
cd "$(dirname "$0")"

APP="build/Horloge Républicaine.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O -parse-as-library Sources/*.swift -o "$APP/Contents/MacOS/HorlogeRepublicaine"
cp Info.plist "$APP/Contents/Info.plist"

echo "Built $APP"
echo "Run it with: open \"$APP\""
