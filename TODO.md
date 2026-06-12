# TODO

## Future features

- **This day in the Revolution**: historical events keyed to Republican dates (18 Brumaire for Napoleon's coup, 9 Thermidor for the fall of Robespierre, 13 Vendémiaire for the whiff of grapeshot...). Show a "ce jour-là" line in the day popover and on the almanac month pages.
- **Engravings**: public domain illustrations for the 366 rural day names, sourced from Wikimedia Commons (the original almanacs were illustrated). Show them in the day popover and almanac. Biggest effort of the four since each image has to be found and credited.

## Done

- [x] Menu bar clock (MenuBarExtra with popover: clock, almanac, quit)
- [x] Browse other months (chevrons in the calendar panel)
- [x] Almanac window with the full lore, all 366 day names translated
- [x] French/English mode
- [x] Click any day for its old-style date
- [x] Date converter, both directions (in the almanac)
- [x] Widget for Notification Center and desktop (small: date + decimal time, medium: adds the dial). Follows the system language since there is no app group; updates once per decimal minute. Built correctly but the gallery rejects ad-hoc signed extensions; needs an Apple Development certificate (one codesign line in build.sh).
- [x] Decimal hour chime: synthesized bells every decimal hour, La Marseillaise at decimal noon. Toggle + preview in the menu bar popover.

## Other ideas

- App icon (a cockade, or a 10-hour watch face)
- Menu-bar-only mode: set `LSUIElement` to `true` in Info.plist to hide the Dock icon (needs a way to toggle it back)
- Option to show the Republican date instead of (or with) the time in the menu bar
- Launch at login via `SMAppService.mainApp.register()`
- True equinox-based year start (Meeus algorithm) as an option, for the calendar purists
- Notification at each new décadi, for the day of rest
- CLI companion that prints decimal time for terminal prompts and tmux status bars
