<!-- gf-brief source=c86fc4085a99a759f0fa95a72f0ad38fe7b74ed4e6a3e7ea57257a46d57b781f written=2026-09-30T03:17:20+03:00 -->
# CR Way
## What it is
CR Way is a Philadelphia Museum of Art matching rail. You save paintings, then hang each waiting canvas under the nameplate that names it, by maker or by title.
It is for people who want that match on this device, not a museum walk, a shop, or an account.

## Launch and onboarding
Cold launch is a short pause on a blank field, then a full-screen splash picture with no words. Appearance stays light.

If this install has not finished the pages, three onboarding pages follow. Page dots read as "Page 1 of 3", "Page 2 of 3", and "Page 3 of 3".

1. Headline "Seat each canvas". Line "Save a museum painting, then hook it under the nameplate that names it." Top-right "Skip" (VoiceOver "Skip onboarding"). Bottom "Continue".
2. Headline "Lift, then hook". Line "Tap a waiting canvas, then the nameplate that belongs with it." "Skip" and "Continue" again.
3. Headline "Keep the rail". Line "Misses stay on Saved. Retract peels the newest mark." No Skip. Bottom "Next".

"Skip" or "Next" closes the pages and opens the home rail. The pages do not show again until "Walk the pages again" or "Erase the rail".

On a physical device the next screen is the empty rail. On Simulator the first run plants a sample rail that is already spread, skips the pages, and opens that rail.

## Screens
There is no tab bar. Home stays on screen. Explore, Saved, Settings, and Spread then hook open as sheets with a drag handle and a trailing X.

### Home — "CR Way"
Title "CR Way". Four icon buttons, VoiceOver "Explore", "Saved", "Settings", and "Spread then hook". They open those sheets.

**Empty rail** (status would be "Bare"). Picture, headline "Rail bare.", line "Save three works, then hook.", bottom "Explore" (opens Explore). If the last rail could not be read: headline "The rail could not be read.", line "Start a fresh crate. Save three works, then hook.", same "Explore".

**Spread rail.** Status chip "Spread". Headline "Seat this painting". Cue is one of:
- "Save three works, then hook." when no painting is in play.
- "{painting title} by {maker}. Tap Seat to hang it under its title." or the same line ending "under its maker."
- After a lift, the same sentence with " is ready" after the maker.

A second chip reads "Nameplates show the maker" or "Nameplates show the title" for this trio. Fault lines, if any, sit under that cue. A recover caption can also show "The rail could not be read."

One large painting and two smaller ones. Under a picture, when it is visible: title, maker on the large tile, and a seat word "Waiting", "Lifted", "Hooked", or "Settled". A lifted tile also shows a peg. A missing picture still shows the title and that seat word. VoiceOver on a tile is "{title}, {maker}, {seat}". Tap a "Waiting" canvas to lift it. Tap a "Hooked" or "Settled" canvas to open Saved.

"Seat this painting" hangs the lifted canvas (or lifts the first waiting canvas, then hangs it) under the nameplate that names it. It is dim when the rail is not spread or nothing is waiting or lifted.

"Seat it here" sits above three nameplates. Each plate shows the maker name or the painting title for this trio, then "Not seated", "Miss, try another", or "Already seated". A miss also strikes the plate text. Tap a plate to try that seat. Plates are dim when "Seat this painting" is dim.

"Recent hooks" is a horizontal strip of the latest seats: nameplate text and a date like "Sep 30". A count tile shows the drop total and "Drops on Saved". A correct seat can flash a mark VoiceOver reads as "Hook seated".

"Retract newest mark" undoes the newest hook or drop. It is dim when there is nothing to peel.

On iPad in a wide layout the three paintings sit on the left. The right column repeats the cue, "Seat this painting", the nameplates, and a "This run" card: "{Bare|Spread|Settled} rail. {n} seated. {n} hooks. {n} drops."

**Settled rail.** Picture, headline "Rail settled.", line "Those three left for Saved. Spread the next trio." Status "Settled". Same recent-hooks strip, drop count, "Spread next", and "Retract newest mark". "Spread next" hangs the next three waiting works when three wait; with fewer than three it returns to "Rail bare."

### Explore
Navigation title "Explore". Trailing X is VoiceOver "Close Explore".

The usual first open is a list, not the empty page. Search field placeholder "Maker or title" (VoiceOver "Search the museum"). Rows show the painting picture or its title initial, title, maker, and "Save". "Save" files that work as waiting. A work already on the rail shows "On the rail" or "Already on the rail." and the button reads "Keep" (VoiceOver "Keep this work on the rail" / "Save this work"). After Save the note "Waiting on the rail." After Keep, "Already on the rail."

While a save is in flight every Save and Keep is dim. A spinner appears while a typed search is running. Failed or empty search keeps the shelf and can show "Showing the local shelf.", "No match. The shelf is still here.", "Search was refused. The shelf is still here.", "Search could not finish. The shelf is still here.", or "Search came back odd. The shelf is still here.", with "Try again".

If the list is truly empty: headline "Shelf is quiet.", line "Search the museum, or save a waiting work from this shelf.", bottom "Search". That "Search" fills the field with "eakins" and runs it.

### Saved
Navigation title "Saved". Trailing X is VoiceOver "Close Saved".

Empty: headline "Nothing seated.", line "Hook a canvas. Marks land here.", bottom "Explore". If the rail could not be written: headline "The rail could not be written.", line "Try retract after the rail writes again.", bottom "Try again".

Populated sections, only when they have rows:
- "Seated" — title, maker, date.
- "Hooks" — nameplate text, maker or "Hooked", chip "Hook", date.
- "Drops" — nameplate text, maker or "Returned to the rail", chip "Drop", date.

Rows are readouts. They do not open a further screen.

### Settings
Navigation title "Settings". Trailing X is VoiceOver "Close Settings".

When no works or marks exist: headline "Rail is empty.", line "Save three works, then hook.", "Explore", then the same sections as below. If a write failed: headline "The rail could not be written.", line "Credit and contact still live below."

Sections:
- "Museum" — "Philadelphia Museum of Art" opens the museum site. "Open access credit" opens the museum open-access page.
- "Rail" — "Retract newest mark" (dim when there is nothing to peel). A fault line can appear here.
- "Help" — "Contact" opens the support page. "Walk the pages again" closes Settings and returns to the three onboarding pages.

Bottom "Erase the rail" opens "Erase this rail?" with "Hooks, drops, and saved works leave this device.", destructive "Erase the rail", and "Keep the rail". Erase wipes the rail on this device and returns to onboarding.

### Spread, then hook
Navigation title "Spread, then hook". Trailing X is VoiceOver "Close spread then hook".

Headline "Spread, then hook". Line "Three canvases. Three nameplates. Lift a painting, then seat it under the cartel that names it." A chip shows "Bare", "Spread", or "Settled", plus "{n} nameplates". Bottom "Seat this painting" closes the sheet and returns to the home rail. This page does not lift or seat by itself.

## Features
- Save Philadelphia Museum of Art paintings from Explore, including a local shelf when search is quiet or fails.
- Search the museum by "Maker or title".
- Keep a work that is already on the rail without adding it twice.
- Spread three waiting works onto one rail with three nameplates.
- Nameplates for a trio are all makers or all titles ("Nameplates show the maker" / "Nameplates show the title").
- Lift a waiting canvas, then seat it under the nameplate that names it.
- "Seat this painting" seats the waiting or lifted canvas under the nameplate that names it.
- A wrong nameplate is a miss: "Miss, try another", the canvas is "Waiting" again, and the miss lands on Saved as a "Drop".
- A right nameplate seats the canvas as "Hooked" ("Already seated" on that plate).
- Three right seats settle the trio ("Rail settled."); those three move to Saved as "Seated".
- "Spread next" hangs the next trio when three works wait.
- "Retract newest mark" peels the newest hook or drop from home or Settings.
- Saved lists "Seated", "Hooks", and "Drops".
- "Recent hooks" and "Drops on Saved" on the home rail.
- "Walk the pages again" and "Erase the rail".
- "Contact", "Philadelphia Museum of Art", and "Open access credit".
- Shortcuts: "Open Quiz", "Open Explore", "Open Saved", "Open Settings", "Spread the rail", "Lift a canvas", "Hook a nameplate". Spoken phrases include "Open Quiz in CR Way", "Hook the rail in CR Way", "Open Explore in CR Way", "Open Saved in CR Way", "Open Settings in CR Way", "Spread the rail in CR Way", "Lift a canvas in CR Way", and "Hook this nameplate in CR Way". Shortcut short titles: "Quiz", "Explore", "Saved", "Settings", "Spread", "Lift", "Hook".

## Behaviours that can look like bugs
- After onboarding on a device, home stays on "Rail bare." / "Save three works, then hook." until three works are saved and the rail is spread. The empty-home pill is "Explore", not "Spread". "Spread" / "Spread next" appears only after a trio has already settled. On a fresh device, after you have saved three works, use the Shortcut "Spread the rail" (or "Spread the rail in CR Way") to hang the first trio.
- "Spread the rail" or "Spread next" with fewer than three waiting works leaves or returns the rail to "Rail bare." with no extra alert.
- "Seat this painting" and the nameplates stay dim until the rail is "Spread" and a canvas is waiting or lifted. Wait for three saved works, spread, then lift or use the pill.
- Other waiting canvases go dim for a moment while a lift is running. Wait for "Lifted" on the one you tapped.
- Save and Keep go dim while one save is running. Wait for "Waiting on the rail." or "Already on the rail."
- "Keep" does not add a second copy. The row shows "On the rail" or "Already on the rail."
- A miss does not end the trio. The plate reads "Miss, try another" and the canvas is "Waiting" again. Lift it and choose another plate, or tap "Seat this painting".
- After three right seats the rail switches to "Rail settled." / "Those three left for Saved. Spread the next trio." That is the end of the trio, not a crash. Use "Spread next" when three more wait.
- "Retract newest mark" is dim, and a tap that still fires can show "Nothing to retract.", until a hook or drop exists.
- Fault lines that refuse a step: "Lift a canvas first.", "Spread the rail first.", "This rail is already spread.", "That canvas is not waiting.", "That canvas is not on this rail.", "That nameplate is not on this rail.", "That work has no accession." Do the named step, or pick a canvas and plate that belong to this trio.
- Search faults keep the shelf on screen. "Try again" or clear the field to see the shelf. The empty Explore "Search" control types "eakins" on purpose.
- If the rail cannot be written: "The rail could not be written." Settings still offers credit and "Contact". Saved offers "Try again".
- If the rail cannot be read: "The rail could not be read." / "Start a fresh crate. Save three works, then hook."
- "Walk the pages again" and "Erase the rail" both return to the three pages. Erase also clears hooks, drops, and saved works.
- Tapping a "Hooked" or "Settled" canvas opens Saved instead of lifting it.

## Starter content and resume
Explore always has a local shelf of eight paintings: "The Gross Clinic" by Thomas Eakins, "Nude Descending a Staircase No. 2" by Marcel Duchamp, "The Peaceable Kingdom" by Edward Hicks, "Prometheus Bound" by Peter Paul Rubens, "The Annunciation" by Henry Ossawa Tanner, "Woman with a Pearl Necklace in a Loge" by Mary Cassatt, "The Burning of the Houses of Lords and Commons" by Joseph Mallord William Turner, and "The Artist in His Museum" by Charles Willson Peale.

On Simulator only, the first run also plants those works on the rail, skips onboarding, and opens a spread already in progress: "The Gross Clinic" is lifted, "Nude Descending a Staircase No. 2" waits on a struck plate, "The Peaceable Kingdom" is hooked, later works wait or are already settled, and Saved already has hooks and drops. A device never gets that planted rail.

Unfinished work resumes. Waiting, lifted, hooked, and settled canvases, hooks, drops, and the current spread come back on the next launch. Finished onboarding stays finished until replay or erase.

## Permissions
None. The app never asks for camera, photos, microphone, location, notifications, or tracking.

## Absent
Genuinely absent: login or accounts, in-app purchase, ads, analytics, user-generated content, an account deletion flow, and an App Tracking Transparency prompt.

## Data and support
Saved works, hooks, and drops stay on this device. "Erase the rail" is the on-screen wipe; its alert says "Hooks, drops, and saved works leave this device."
Explore looks up the museum collection when you type a search; a failed search still shows the local shelf. Painting pictures can load from the museum's open-access images.
Settings → "Help" → "Contact" opens the support page.

## Scanning and health
None. The app does not scan barcodes or QR codes. It does not show health, medical, or product-health information.

## Platform
English only. No language or region switch. Dates on marks look like "Sep 30". Search copy is English. The collection is the Philadelphia Museum of Art.
Portrait only, light appearance, full screen. iPhone and iPad. Wide iPad uses the two-column home. Minimum iOS 17.0.

## Category
Education
