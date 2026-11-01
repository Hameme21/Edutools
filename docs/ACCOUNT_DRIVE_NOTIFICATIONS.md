# Account, Drive and Android notification update

## Drive Sync button

The Sync button now looks for `educal_sync_data.json` in the selected Google account's Drive. If found, it downloads and applies that routine, including an empty class list. If missing, it creates the JSON from the current routine. Sync does not overwrite an existing file. Lookup, permission and malformed-file failures leave the local routine in place and report failure. Routine changes are then sent to the shared account backend for the other client.

Google Drive permission is requested on explicit Sync, using the same Google account as Edutools. The existing `drive.file` scope is retained: Google only exposes files created by or previously authorized for this app. An unrelated JSON manually uploaded to Drive may not be visible to that scope. Google Drive API must be enabled in the project's Google Cloud API library. In a Google OAuth project in Testing mode, the user may need to be included among its test users to grant Drive access.

## Registration and returning users

All registration screens offer CSE, DS, BBA, CE, EDS, EEE and BSE. New Google users must finish their name, student ID and department before receiving an app session or accessing the dashboard. The web registration gate is opaque and cannot be skipped.

The backend validates Firebase ID-token signatures against Google's public signing certificates and checks the project, expiry, Google provider and verified email. Google's verified email is the email-verification step; a second emailed link is not sent for Google sign-in. Registered Google users receive a session directly. Browser and app sessions are saved locally for return visits. Password sign-in also avoids email-verification links. If a user signs out and chooses passwordless email-link sign-in, a fresh sign-in link is still required to prove identity.

No Firebase SMTP setting or disabling of verification is needed. Keep the existing Google provider enabled and the corrected Android signing fingerprint. `FIREBASE_PROJECT_ID` defaults to `edutools-e2558` and is included in the Render blueprint; it must match the Firebase project used by both clients.

Registered profiles are persisted to MongoDB and loaded on backend startup. Keep `MONGODB_URI` configured in Render. Without a persistent database, Render restarts can lose registrations even when local browser sessions remain.

## Android notifications

The existing Enable Notifications screen now requests Android's real runtime notification permission. A new preference key lets users who saw the older informational screen receive this real prompt once. Denial is respected, and users can enable notifications later in Android Settings.

Notification categories are Classes, Events, Semester fees, Exams and Holidays. The existing reminder engine determines times, custom reminder settings, and holiday suppression. Future reminders are persisted natively; one AlarmManager event schedules the next due reminder, including after a reboot. Android notification channels let users adjust each category separately.

Exact timing uses the Android Alarms & reminders special access when granted. Otherwise Android's inexact scheduling is used and reminders can be delayed by the system. Notifications are local reminders; Firebase Cloud Messaging is not required. The schedule covers the next 21 days and refreshes when the app recalculates reminders; open the app periodically to refresh that horizon.

## Deploy and verify

1. Deploy the updated backend (including the Google session service and RegisteredStudent model) to Render with MongoDB configured.
2. Deploy the updated root `index.html` website.
3. Install APK 1.1.7 build 20 over the existing app.
4. Test one new Google account: complete department registration without seeing the dashboard behind it. Then reopen the same browser and test a returning registered account without another emailed verification link.
5. Test Sync with no Drive JSON, then with an existing JSON whose routine differs locally. Check that an existing file is applied, not overwritten.
6. On Android, select Enable Notifications and allow the system permission. In Android Settings > Apps > Edutools > Notifications, check the separate categories. Check a scheduled reminder on the device; automated tests validate scheduling payloads but do not simulate Android's background-delivery policy.
