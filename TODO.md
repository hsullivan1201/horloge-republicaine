# TODO

## Future features

- **This day in the Revolution**: historical events keyed to Republican dates (18 Brumaire for Napoleon's coup, 9 Thermidor for the fall of Robespierre, 13 Vendémiaire for the whiff of grapeshot...). Show a "ce jour-là" line in the day popover and on the almanac month pages.
- **Engravings**: Prairial and Messidor (months 8 and 9) are done; the other ten months each need their own list in Engravings.swift. Messidor covers 16 of 30 days (Besler 1640 copperplates plus a few Köhler plates for harvest staples); the cereals (rye, oat), alliums (garlic, shallot), exotic clove, bean, vetch, the three animals (mule, chamois, guineafowl) and tools (sickle, shawm, parc) have no good frame-filling plate and are left imageless. Same gaps will recur each month for animals/tools — might want a fallback set of Gessner woodcuts (animals) and Encyclopédie plates (tools). Could also auto-trim the cream scan margins inside each plate.

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
