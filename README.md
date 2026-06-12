# Horloge Républicaine

A tiny native macOS app that tells time the way the French Revolution wanted you to.

In 1793 the National Convention decreed that the day would have 10 hours, each hour 100 minutes, each minute 100 seconds. They also replaced the Gregorian calendar with 12 months of exactly 30 days (three "décades" of 10 days each), plus 5 or 6 festival days at the end of the year called the sans-culottides. Every day of the year honors a plant, animal, mineral or farm tool instead of a saint. Decimal time lasted about 17 months. This app keeps the dream alive.

## What it does

- Lives in your menu bar, ticking in decimal seconds (one every 0.864 normal seconds), with a quick popover
- Analog 10-hour dial, like the actual decimal watch faces made in the 1790s (the hour hand makes one full turn per day)
- Today's Republican date, e.g. `Quartidi 24 Prairial · An CCXXXIV`, with the rural day name
- Calendar grid of any month, 3 décades of 10 days, with today circled. Arrows to browse the year, hover any day to see what it's consecrated to
- An Almanac window for digging into the lore: how decimal time worked, the ten weekday names and their Latin roots, every month with all 30 day names and English translations, the etymology of each month name, the British nicknames (Wheezy, Sneezy, Freezy...), and the sans-culottides
- A date and time converter in both directions, for deciphering revolutionary documents or finding your Republican birthday
- Click any day for its old-style (Gregorian) date
- French or English interface, toggle anywhere
- A widget for the Notification Center sidebar and the desktop (the medium size includes the dial). Add it via Edit Widgets after launching the app once
- Conventional time at the bottom, for the unconverted

## Building

You only need the Xcode command line tools (just `swiftc`, no Xcode project):

```sh
./build.sh
open "build/Horloge Républicaine.app"
```

Pure SwiftUI, zero dependencies, one small binary.

## How the calendar is computed

Each Republican year starts on September 22, the Gregorian date of 1 Vendémiaire An I (and still roughly the autumn equinox). Anchoring to the fixed Gregorian date keeps everything self-consistent: a Republican year that spans a February 29 automatically gets a 6th complementary day. Historians argue about the "right" leap rule since the calendar was abolished before settling the question, so this is one defensible choice among several.

Decimal time is computed from local midnight, so it stays correct across DST changes (those days just have slightly faster or slower decimal seconds, which feels appropriately revolutionary).
