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

# The app and widget share settings (language, appearance) through an app
# group. On macOS a group prefixed with the team ID needs no provisioning
# profile, just both binaries signed by that team. The team ID is the OU of
# the signing certificate. Ad hoc builds skip the group and the widget
# follows the system language instead.
APP_ENT="build/app.entitlements"
WIDGET_ENT="build/widget.entitlements"
cp Widget/widget.entitlements "$WIDGET_ENT"
printf '<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0"><dict/></plist>\n' > "$APP_ENT"
if [ "$IDENTITY" != "-" ]; then
    TEAM=$(security find-certificate -c "$IDENTITY" -p | openssl x509 -noout -subject | sed -n 's/.*OU *= *\([A-Z0-9]*\).*/\1/p')
    GROUP="$TEAM.horloge-republicaine"
    echo "App group: $GROUP"
    for ENT in "$APP_ENT" "$WIDGET_ENT"; do
        /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups array" \
            -c "Add :com.apple.security.application-groups:0 string $GROUP" "$ENT"
    done
    plutil -insert AppGroupID -string "$GROUP" "$APP/Contents/Info.plist"
    plutil -insert AppGroupID -string "$GROUP" "$APPEX/Contents/Info.plist"
fi

codesign --force -s "$IDENTITY" --entitlements "$WIDGET_ENT" "$APPEX"
codesign --force -s "$IDENTITY" --entitlements "$APP_ENT" "$APP"

echo "Built $APP"
echo "Run it with: open \"$APP\""
