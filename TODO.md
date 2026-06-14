# TODO

## Future features

- **This day in the Revolution**: historical events keyed to Republican dates (18 Brumaire for Napoleon's coup, 9 Thermidor for the fall of Robespierre, 13 Vendémiaire for the whiff of grapeshot...). Show a "ce jour-là" line in the day popover and on the almanac month pages.
- **Engravings**: two follow-ups. (1) Extend past Prairial — only month 8 is filled in; each other month needs its own list in Engravings.swift. (2) Upgrade more Prairial days to frame-filling Besler 1640 plates. Days 2, 8, 11, 16, 17, 18 now use uncolored Besler engravings (grey, no whitespace); the rest fall back to their original plate, desaturated to grey in-app. Humble herbs (clover, thyme, pea, balm) only appear as side sprigs in Besler, so they'd need a different frame-filling source (Fuchs woodcuts?) or stay as greyed fallbacks. Could also auto-trim the cream scan margins inside each plate.

## Done

- [x] Menu bar clock (MenuBarExtra with popover: clock, almanac, quit)
- [x] Browse other months (chevrons in the calendar panel)
- [x] Almanac window with the full lore, all 366 day names translated
- [x] French/English mode
- [x] Click any day for its old-style date
- [x] Date converter, both directions (in the almanac)
- [x] Widget for Notification Center and desktop (small: date + decimal time, medium: adds the dial). Follows the system language since there is no app group; updates once per decimal minute. Built correctly but the gallery rejects ad-hoc signed extensions; needs an Apple Development certificate (one codesign line in build.sh).
- [x] Decimal hour chime: La Marseillaise on synthesized bells at every decimal hour. Toggle + preview in the menu bar popover.

## Other ideas

- App icon (a cockade, or a 10-hour watch face)
- Menu-bar-only mode: set `LSUIElement` to `true` in Info.plist to hide the Dock icon (needs a way to toggle it back)
- Option to show the Republican date instead of (or with) the time in the menu bar
- Launch at login via `SMAppService.mainApp.register()`
- True equinox-based year start (Meeus algorithm) as an option, for the calendar purists
- Notification at each new décadi, for the day of rest
- CLI companion that prints decimal time for terminal prompts and tmux status bars
