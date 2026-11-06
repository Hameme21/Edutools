Section Planner — Fall 2026

The bundled catalog contains all 791 rows (1,296 weekly meetings) from the supplied
“Class Routine with faculty assign Fall 2026.pdf”. Its offerings cover BSCSE and
BSDS only. It does not claim to include other departments or live registration
availability. Conditional sections retain their “if required” note. TBA faculty
is displayed as “To be announced”.

Times retain the PDF's minute values, with explicit AM/PM converted to 24-hour
time. For example, 12:31 PM is 12:31, 01:50 PM is 13:50, and the CSE 2216 L lab
is Wednesday 11:11–13:40. Single-day labs and both meetings of theory sections are
retained. PDF pages 28–54 contain no offering rows.

The import script combines pdfplumber's table boundaries with PyMuPDF's text
drawing origins. This avoids pulling overflowing title/room/faculty glyphs into
neighboring columns. It asserts consecutive source row IDs 1–791 and validates
every weekday, clock value and positive meeting duration. Source page and row
numbers remain in the generated JSON for auditing.

Rebuild the catalog with Python packages pdfplumber and pymupdf:

    python scripts/import_section_offerings.py PDF_PATH FACULTIES_JSON_PATH

Course entry shares the native Course Planner catalog. The website uses the
matching sample_data/course_catalog.json. Faculty suggestions come from the
supplied faculties.json and remain editable; instructor input starts empty.
Exact known titles fill missing course codes; unknown titles are not guessed.
Selecting a course and section fills the assigned instructor automatically.
Section identifiers are retained in saved routines. Section-tagged imports can
fill missing faculty from the same catalog; ambiguous or unknown matches are
not guessed. Existing instructor corrections and the routine Edit action remain
available.

Section Planner is the last tool in Tools. Search a course code/title, then
filter its section names or faculty names/initials in the separate section
search box and add a section.
The Unified Class Routine shows active sections together with other configured
courses in a Saturday–Friday hour grid. Cards retain their exact minute-based
positions and durations. Overlaps are red and placed in separate vertical lanes
so neither class is hidden. Phones can scroll the timeline horizontally.
The section plan underneath lists active choices and saved backups. Clearing
the section plan clears only the draft choices, not configured routine classes.

After the configured routine end date passes (the last day remains inclusive),
the planner stops including that semester's configured classes. Its old draft
is reset once for that end date. The reset marker and draft save timestamp keep
new selection preparation intact on reopening. The app checks on open/resume
and once a minute while open; the web checks when opened/used and once a minute.
Without a routine end date, no automatic expiration is guessed.

Automatic cleanup does not delete the saved routine. Explicitly applying a new
plan after expiration starts a new routine without the previous semester's
classes and clears its old date range. Set the new dates in Class Setup.

Select one active section per course and any number of backup sections. Backups
are compared against the active sections of other courses and configured
classes, but are not simultaneous classes. “Make active” switches the choice.
Back-to-back meetings are allowed. Overlapping meetings on the same weekday
block applying an active plan. Each meeting is compared, including lab times.

Applying replaces existing meetings for the selected course codes and preserves
all other configured courses. Only active sections enter the routine and its
normal account/Drive sync; backup drafts are stored locally per account/device.
Web drafts use localStorage; app drafts use SharedPreferences.

The website needs section_planner.js and the three sample_data JSON assets
deployed alongside index.html. The Android APK bundles those JSON assets for
offline use. No Firebase or MongoDB schema/configuration change is required.
