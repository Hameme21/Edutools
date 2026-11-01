# Mobile and website routine synchronization

The mobile app and root `index.html` website use `/api/student/sync` on the same Render backend. Personal classes and their active date range are saved under a normalized account email. Official notices use the separate global calendar routes; personal classes are no longer applied from global broadcasts.

Changes:
- Mobile login pulls the saved account routine instead of uploading an empty local routine.
- Imports and edits upload directly to the account endpoint without waiting for Google Drive.
- Room, instructor, color, reminder and end-time edits are compared, not just course code and start time.
- An intentionally empty routine clears the other device, including deletion of the last class.
- Routine date ranges are persisted and synchronized.
- Local edits made during a network pull are queued and protected from the old response.
- Failed writes remain pending and are retried by the next polling tick; a failed request is not reported as successful sync.
- `syncVersion: 1` distinguishes intentional empty routines from empty snapshots created by older clients. During migration an existing nonempty local routine replaces a legacy empty cloud snapshot.

## Deployment order

1. Deploy the updated Node backend to Render, including `routes/api.js` and `models/StudentSchedule.js`.
2. Deploy the updated root `index.html` to Vercel.
3. Because the correct routine is currently on the website, open that updated website first while signed into the correct account. The first pull restores the cloud copy if it contains a legacy empty snapshot. A locally saved routine is migrated only if the account has no saved routine or its old cloud snapshot is empty.
4. Install the updated APK over the existing app, keeping its data. Sign in using the exact same email and allow the three-second polling interval to fetch the routine.
5. Verify the course list and date range on both clients, then check a room/time edit in each direction.

Keep `MONGODB_URI` configured and the Render database connection healthy. Without MongoDB the existing backend falls back to memory; those snapshots do not survive a restart. These changes do not provision a database.

Before refreshing or redeploying, export the known-good website routine as an extra copy. If the old app already erased the server copy and the browser no longer retains it, reimport that exported routine in the updated website.

Run the focused checks:
```
cd backend
node --test tests/cross_platform_sync.test.js
```
```
flutter test test/student_routine_sync_test.dart
```

These tests use local/mocked servers and isolated test storage. The protocol uses the last completed upload for conflicting edits from different devices; it does not merge simultaneous edits to the same routine. Existing authentication/authorization of the student-sync endpoints is outside this change.
