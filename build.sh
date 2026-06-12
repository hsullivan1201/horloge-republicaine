#!/bin/sh
# Builds Horloge Républicaine.app into build/, widget extension included.
# No Xcode project needed, just the command line tools.
set -e
cd "$(dirname "$0")"

# ExtensionKit layout (Contents/Extensions): the only widget format the
# macOS gallery picks up for native Mac apps. PlugIns/NSExtension is the
# legacy iOS-style form and gets silently ignored.
APP="build/Horloge Républicaine.app"
APPEX="$APP/Contents/Extensions/HorlogeWidget.appex"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APPEX/Contents/MacOS"

swiftc -O -parse-as-library Sources/*.swift -o "$APP/Contents/MacOS/HorlogeRepublicaine"
cp Info.plist "$APP/Contents/Info.plist"

# The widget shares the calendar logic and theme but has its own @main.
# Entry point must be Foundation's _NSExtensionMain (what Xcode links app
# extensions with); with Swift's default main the process exits before
# serving XPC and the widget never appears in the gallery.
swiftc -O -parse-as-library -target arm64-apple-macos14.0 \
    Sources/CalendarData.swift Sources/RepublicanCalendar.swift Sources/Theme.swift \
    Widget/HorlogeWidget.swift \
    -framework Foundation \
    -Xlinker -e -Xlinker _NSExtensionMain \
    -o "$APPEX/Contents/MacOS/HorlogeWidget"
cp Widget/Info.plist "$APPEX/Contents/Info.plist"

# Extensions only load if they are sandboxed and signed (ad hoc is fine
# locally). Sign inside-out: appex first, then the app.
codesign --force -s - --entitlements Widget/widget.entitlements "$APPEX"
codesign --force -s - "$APP"

echo "Built $APP"
echo "Run it with: open \"$APP\""
