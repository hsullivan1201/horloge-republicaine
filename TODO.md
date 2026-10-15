# TODO

## Future features

- **This day in the Revolution**: historical events keyed to Republican dates (18 Brumaire for Napoleon's coup, 9 Thermidor for the fall of Robespierre, 13 Vendémiaire for the whiff of grapeshot...). Show a "ce jour-là" line in the day popover and on the almanac month pages.

## Release checks

- [x] Build the iOS targets with full Xcode and verify the app plus the Home Screen and Lock Screen widgets on a simulator
- [ ] Verify on a physical iPhone, including that the app group provisions with your team
- [ ] Check whether `WidgetCenter.reloadAllTimelines()` works on device. In the iOS 26.5 simulator chronod refuses it (ChronoCoreErrorDomain 10, and 27 for `reloadTimelines(ofKind:)`), so the widget picks up language and theme changes at its hourly refresh instead of right away

## Done

- [x] Mac widget now shows up in the gallery. It never had: macOS couldn't find the extension inside "Horloge Républicaine.app" because of the é, so the bundle folder is now `HorlogeRepublicaine.app` with a localized display name. `./build.sh install` moves the build into /Applications
- [x] App icon (Mac and iPhone): tricolor cockade around the 10-hour dial, drawn by `Icon/make-icon.swift`

- [x] Redesign: enamel dial with an inner 24-hour ring and Breguet hands, Didot type, two-column Mac window, faded past days and shaded décadi column
- [x] Nuit theme (and Auto), replacing the forced light mode. Applies to the Mac windows, menu bar panel, iPhone app and widgets
- [x] Menu bar display options: time, tiny dial, or date
- [x] Lock Screen widgets (circular dial, rectangular, inline), StandBy, and a live decimal-hour bar on the Home Screen widgets
- [x] Widget follows the app's language and theme through an app group
- [x] Fixes: menu bar seconds aligned to real decimal-second boundaries, day names no longer doubled in English ("Amaryllis · Amaryllis"), Mac views use the Gregorian calendar explicitly, only the clock redraws every second, iPhone calendar no longer drops days 1 to 9

- [x] Menu bar clock (MenuBarExtra with popover: clock, almanac, quit)
- [x] Browse other months (chevrons in the calendar panel)
- [x] Almanac window with the full lore, all 366 day names translated
- [x] French/English mode
- [x] Click any day for its old-style date
- [x] Date converter, both directions (in the almanac)
- [x] Widget for Home Screen, Notification Center, and desktop (small: date + decimal time, medium: adds the dial). Follows the system language since there is no app group; requests updates every five decimal minutes, subject to WidgetKit scheduling. The macOS gallery needs a real Apple Development signature; build.sh picks up the identity from the keychain automatically. If signing breaks with "unable to build chain", the WWDR G3 intermediate is missing: download it from apple.com/certificateauthority and `security add-certificates` it.
- [x] Decimal hour chime: La Marseillaise on synthesized bells at every decimal hour. Toggle + preview in the menu bar popover.
- [x] Native iPhone app with clock, touch calendar, almanac/converter, settings, deep linking, and an embedded small/medium Home Screen widget
- [x] iOS app icon based on the 10-hour dial and tricolor cockade

## Other ideas

- Menu-bar-only mode: set `LSUIElement` to `true` in Info.plist to hide the Dock icon (needs a way to toggle it back)
- Launch at login via `SMAppService.mainApp.register()`
- True equinox-based year start (Meeus algorithm) as an option, for the calendar purists
- Notification at each new décadi, for the day of rest
- CLI companion that prints decimal time for terminal prompts and tmux status bars
