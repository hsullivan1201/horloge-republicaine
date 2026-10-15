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

# Extensions only load if they are sandboxed and signed with a real
# identity: the widget gallery (chronod) silently ignores ad-hoc signed
# extensions. Sign inside-out: appex first, then the app. Falls back to
# ad hoc if no Apple Development identity is in the keychain.
IDENTITY=$(security find-identity -v -p codesigning | grep -om1 '"Apple Development: [^"]*"' | tr -d '"')
[ -n "$IDENTITY" ] || IDENTITY="-"
echo "Signing as: $IDENTITY"
codesign --force -s "$IDENTITY" --entitlements Widget/widget.entitlements "$APPEX"
codesign --force -s "$IDENTITY" "$APP"

echo "Built $APP"
echo "Run it with: open \"$APP\""
