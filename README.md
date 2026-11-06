# Edutools

Edutools is an academic calendar, class routine, and section planning app for United International University students. It combines a Flutter Android app, a browser companion, and a Node.js backend for accounts and routine synchronization.

- [Open the website](https://edutools-silk.vercel.app/)
- [Download the latest Android release](https://github.com/Hameme21/Edutools/releases/latest)
- [Backend health](https://edutools-y4xy.onrender.com/api/health)

Current release: **1.2.3**, Android build **130**.

## Features

- View recurring classes alongside academic notices, holidays, exams, and semester fee deadlines.
- Import and export supported ICS, JSON, and CSV routines, or configure classes manually.
- Set routine dates using academic calendar suggestions or custom start/end dates.
- Search Course Planner courses to fill course codes automatically; search faculty names or initials in a blank, editable instructor input.
- Use the academic calendar, CGPA calculator, exam routine, division/tuition calculator, Course Planner, and Section Planner tools.
- Receive Android reminders through separate categories for classes, events, semester fees, exams, and holidays.
- Sign in with Google or supported email flows and synchronize routines between Android and the website.

## Section Planner

Section Planner is the last item in Tools. Search a course, then use the section search to find a section, faculty name, or faculty initial.

The Unified Class Routine displays Saturday through Friday with hour headings and cards positioned at exact meeting times. Conflicts appear in red on separate lanes; back-to-back classes are allowed. The timetable scrolls horizontally on phones.

Choose one active section per course and keep multiple backups. Backups enter the timetable only when made active. Applying a plan adds the active meetings to your routine and preserves other current courses.

The bundled Fall 2026 catalog contains **791 BSCSE/BSDS offerings**, **1,296 meetings**, and **348 faculty suggestions** from the supplied PDF and faculty JSON. It is not a live registration or seat-availability feed. Other departments' offerings are not included. TBA means **To be announced**.

After the configured routine end date passes, old semester classes are excluded from the planner and its old draft resets once. New preparation survives reopening. Automatic cleanup leaves the saved routine intact. Explicitly applying a new plan after expiry starts a new routine; set its new dates in Class Setup.

Backup drafts stay local to each account/device or browser. Only applied routine classes participate in account and Drive sync. See [Section Planner details and data import](docs/SECTION_PLANNER.md).

## Accounts and cloud sync

New Google users enter their name, student ID, and department before accessing the app. The name starts blank. Registered Google users reuse their stored profile without another registration or separate email-verification link. Registration offers CSE, DS, BBA, CE, EDS, EEE, and BSE.

| Feature | Behavior |
| --- | --- |
| Account sync | Synchronizes routine classes and date ranges through the backend for the signed-in account. |
| Cloud Sync / Drive | Requests access for that Google account. Restores an existing `educal_sync_data.json`, or creates it if missing. Sync does not overwrite an existing Drive snapshot. |

Drive requests the `drive.file` scope for files used by this app. An unrelated manually uploaded file may not be visible. Google consent and an enabled Google Drive API are required. Verification emails use Brevo's HTTPS API; Firebase SMTP setup is not required.

MongoDB must be connected for persistent Google registration. A configured `MONGODB_URI` alone does not confirm connectivity: inspect `database.connected` in `/api/health`.

## Android installation and updates

Install the APK from [GitHub Releases](https://github.com/Hameme21/Edutools/releases/latest) over your existing app. The package is `com.example.educal`. Compatible updates retain the same package and signing certificate, preserving the installation and app data.

For developer installation, identify and explicitly target the phone's current profile:

```sh
adb devices -l
adb -s DEVICE_SERIAL shell am get-current-user
adb -s DEVICE_SERIAL install --user PROFILE_ID -r Edutools-1.2.3.apk
```

The current Gradle release configuration uses the existing development signing key. Retain that key for compatible APK updates; configure a dedicated signing strategy before Play Store distribution. Android is the verified release target; other Flutter platform folders are development scaffolding.

Automatic update prompts appear only for a newer release than the installed app version. Android notification permission is separate. Exact reminder timing depends on alarm permission and system battery restrictions. Reminder schedules refresh when the app recalculates them and cover a 21-day horizon.

## Development

### Flutter app

Install Flutter, the Android SDK, and a compatible Java toolchain. This release was built with Flutter 3.47.2.

```sh
flutter pub get
flutter run
flutter build apk --release
```

Firebase configuration in `lib/firebase_options.dart` and `android/app/google-services.json` must match the Firebase project, Android package, and signing fingerprint. `ApiService.productionBaseUrl` controls the Android backend address.

### Website

Serve the repository root:

```sh
python -m http.server 8080
```

Open `http://localhost:8080`. Deploy `index.html`, `section_planner.js`, and `sample_data/` together. `vercel.json` forwards API requests to Render; the website also supports its configured production backend address.

### Backend

See [backend setup and environment variables](backend/README.md).

## Project layout

| Path | Purpose |
| --- | --- |
| `lib/` | Flutter screens, schedule models, reminders, authentication, and sync services. |
| `index.html` | Main browser app, styles, and interactions. |
| `section_planner.js` | Web section selection, unified timetable, faculty filtering, and semester rollover. |
| `backend/` | Express API, MongoDB models, Firebase token verification, and Brevo email delivery. |
| `sample_data/` | Academic/sample data, course catalog, faculty list, and Fall 2026 offerings bundled in the app. |
| `scripts/import_section_offerings.py` | Rebuilds the section catalog from the supplied PDF and faculty JSON. |
| `test/`, `backend/tests/` | Flutter and Node regression tests. |

## Validation and further reading

Run checks appropriate to the change. For planner and update behavior:

```sh
flutter test test/section_planner_test.dart test/student_routine_sync_test.dart test/app_update_test.dart test/update_alert_test.dart
node --test backend/tests/section_planner.test.js
```

See [email setup](docs/EMAIL_SETUP.md), [routine sync](docs/ROUTINE_SYNC.md), and [registration recovery](docs/REGISTRATION_RECOVERY.md). Keep API keys, database credentials, environment files, and signing keys out of commits and release assets.
