# TODO

## Future features

- **This day in the Revolution**: historical events keyed to Republican dates (18 Brumaire for Napoleon's coup, 9 Thermidor for the fall of Robespierre, 13 Vendémiaire for the whiff of grapeshot...). Show a "ce jour-là" line in the day popover and on the almanac month pages.
- **Desktop widget**: WidgetKit widget with the 10-hour dial or today's Republican date. Needs an app group if it shares settings with the app.
- **Decimal hour chime**: a soft bell at each new decimal hour (every 2h24 of old time), maybe something grander at decimal noon (5:00). Needs a setting to turn it off.
- **Engravings**: public domain illustrations for the 366 rural day names, sourced from Wikimedia Commons (the original almanacs were illustrated). Show them in the day popover and almanac. Biggest effort of the four since each image has to be found and credited.

## Done

- [x] Menu bar clock (MenuBarExtra with popover: clock, almanac, quit)
- [x] Browse other months (chevrons in the calendar panel)
- [x] Almanac window with the full lore, all 366 day names translated
- [x] French/English mode
- [x] Click any day for its old-style date
- [x] Date converter, both directions (in the almanac)

## Other ideas

- App icon (a cockade, or a 10-hour watch face)
- Menu-bar-only mode: set `LSUIElement` to `true` in Info.plist to hide the Dock icon (needs a way to toggle it back)
- Option to show the Republican date instead of (or with) the time in the menu bar
- Launch at login via `SMAppService.mainApp.register()`
- True equinox-based year start (Meeus algorithm) as an option, for the calendar purists
- Notification at each new décadi, for the day of rest
- CLI companion that prints decimal time for terminal prompts and tmux status bars
