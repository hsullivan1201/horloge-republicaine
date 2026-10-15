#!/bin/sh
# Builds the Mac app into build/, widget extension included.
# No Xcode project needed, just the command line tools.
#
#   ./build.sh            build into build/
#   ./build.sh install    build, then move it into /Applications
set -e
cd "$(dirname "$0")"

# ExtensionKit layout (Contents/Extensions): the only widget format the
# macOS gallery picks up for native Mac apps. PlugIns/NSExtension is the
# legacy iOS-style form and gets silently ignored.
#
# The bundle folder name must stay ASCII. ExtensionKit looks the widget up
# by URL with the é decomposed (e + U+0301) while LaunchServices stores the
# path as written (precomposed), so inside "Horloge Républicaine.app" the
# lookup fails with "not found in LS database" and the widget never reaches
# the gallery. Finder and the Dock still show the accented name through
# LSHasLocalizedDisplayName and MacResources/*.lproj/InfoPlist.strings.
APP="build/HorlogeRepublicaine.app"
APPEX="$APP/Contents/Extensions/HorlogeWidget.appex"
rm -rf "$APP" "build/Horloge Républicaine.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APPEX/Contents/MacOS"

swiftc -O -parse-as-library Sources/*.swift -o "$APP/Contents/MacOS/HorlogeRepublicaine"
cp Info.plist "$APP/Contents/Info.plist"
# Icon is drawn by Icon/make-icon.swift.
cp Icon/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp -R MacResources/ "$APP/Contents/Resources/"

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

if [ "$1" = "install" ]; then
    # Move rather than copy: two registered copies of the same widget make
    # chronod pick one at random, and a stale one never launches.
    DEST="/Applications/HorlogeRepublicaine.app"
    LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
    osascript -e 'tell application id "com.estonianspy.horloge-republicaine" to quit' 2>/dev/null || true
    sleep 1
    for OLD in "$DEST" "/Applications/Horloge Républicaine.app"; do
        [ -e "$OLD" ] && "$LSREGISTER" -u "$OLD" && rm -rf "$OLD"
    done
    "$LSREGISTER" -u "$APP" 2>/dev/null || true
    mv "$APP" "$DEST"
    "$LSREGISTER" -f "$DEST"
    open "$DEST"
    echo "Installed $DEST"
else
    echo "Run it with: open \"$APP\", or install it with: ./build.sh install"
fi
