# Horloge Républicaine

A native iPhone and macOS app that tells time the way the French Revolution wanted you to.

In 1793 the National Convention decreed that the day would have 10 hours, each hour 100 minutes, each minute 100 seconds. They also replaced the Gregorian calendar with 12 months of exactly 30 days (three "décades" of 10 days each), plus 5 or 6 festival days at the end of the year called the sans-culottides. Every day of the year honors a plant, animal, mineral or farm tool instead of a saint. Decimal time lasted about 17 months. This app keeps the dream alive.

## What it does

- On iPhone: a touch-first tab layout for the live clock, 10-column calendar, full almanac and converter, and settings
- On macOS: a two-column window (dial on the left, date and calendar on the right) plus a menu bar clock ticking in decimal seconds (one every 0.864 normal seconds). The menu bar can show the time, a tiny dial, or the date; pick in the popover
- Plays the opening of La Marseillaise on synthesized bells at each new decimal hour (every 2 h 24 of old time). On iPhone this runs while the app is open; toggle it in Settings or the macOS menu bar popover
- Analog 10-hour enamel dial with Breguet-style hands, like the decimal clocks made in the 1790s. The hour hand makes one full turn per day, so a small 24-hour ring inside reads off the same hand, just like the period clocks that showed both
- Set in Didot, the typeface Firmin Didot was cutting in Paris in those same years (it ships with macOS and iOS)
- Jour and Nuit themes: parchment by day, ink blue and gilt at night. Auto follows the system
- Today's Republican date, e.g. `Quartidi 24 Prairial · An CCXXXIV`, with the rural day name
- Calendar grid of any month, 3 décades of 10 days, with today circled, past days faded and the décadi (day of rest) column shaded. Tap or click any day to see what it's consecrated to
- An Almanac for digging into the lore: how decimal time worked, the ten weekday names and their Latin roots, every month with all 30 day names and English translations, the etymology of each month name, the British nicknames (Wheezy, Sneezy, Freezy...), and the sans-culottides
- A date and time converter in both directions, for deciphering revolutionary documents or finding your Republican birthday
- Tap or click any day for its old-style (Gregorian) date
- French or English interface, toggle anywhere
- Small and medium widgets for the iPhone Home Screen, StandBy, macOS Notification Center, and desktop (the medium size includes the dial), with a bar that fills live through the decimal hour
- Lock Screen widgets on iPhone: a round dial, a rectangle with the time, date and dedication, and an inline line above the clock
- Widgets follow the app's language and theme through a shared app group
- Conventional time at the bottom, for the unconverted

## Building for iPhone

The iPhone app and Home Screen widget need full Xcode 15 or newer; Command Line Tools alone do not include the iOS SDK.

1. Open `HorlogeRepublicaine.xcodeproj` in Xcode.
2. Select the `HorlogeRepublicaine-iOS` target, then choose your Apple Development team under **Signing & Capabilities**. Use the same team for `HorlogeWidget-iOS`.
3. Choose an iPhone simulator or connected iPhone and run the `HorlogeRepublicaine-iOS` scheme.
4. After launching once, touch and hold the Home Screen, choose **Edit → Add Widget**, and search for **Horloge Républicaine**.

The app and widget share settings through the app group `group.com.estonianspy.horloge-republicaine`, so your team needs the App Groups capability (Xcode adds it under Signing & Capabilities). Without it, remove the two `.entitlements` lines from the targets and the widget falls back to the system language and appearance.

The simulator does not need a signing identity. A physical iPhone must be trusted, have Developer Mode enabled, and use bundle identifiers available to your development team.

## Building for macOS

You only need the Xcode command line tools (just `swiftc`, no Xcode project):

```sh
./build.sh install
```

That builds the app and moves it to `/Applications/HorlogeRepublicaine.app`. Plain `./build.sh` only builds it into `build/`. Install by moving rather than copying: if macOS knows about two copies, the widget may launch from the wrong one.

The folder name has no accent on purpose. With the é in the path, macOS can't find the widget extension and it never shows up in the widget gallery. Finder and the Dock still show "Horloge Républicaine".

The icon is drawn in code by `Icon/make-icon.swift` (`swift Icon/make-icon.swift` rebuilds the Mac `.icns` and the iPhone app icon).

Pure SwiftUI, with zero third-party dependencies.

build.sh signs with your Apple Development identity if it finds one, and sets up a team-prefixed app group (`TEAMID.horloge-republicaine`) so the widget can read the app's language and theme. macOS doesn't need a provisioning profile for that.

## How the calendar is computed

Each Republican year starts on September 22, the Gregorian date of 1 Vendémiaire An I (and still roughly the autumn equinox). Anchoring to the fixed Gregorian date keeps everything self-consistent: a Republican year that spans a February 29 automatically gets a 6th complementary day. Historians argue about the "right" leap rule since the calendar was abolished before settling the question, so this is one defensible choice among several.

Decimal time is computed from local midnight, so it stays correct across DST changes (those days just have slightly faster or slower decimal seconds, which feels appropriately revolutionary).
