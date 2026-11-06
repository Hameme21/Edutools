# Edutools backend

The Edutools Express API handles student registration, Google/Firebase sessions, email sign-in and recovery, routine synchronization, uploads, and academic calendar data. MongoDB stores registered profiles and routine snapshots. Brevo delivers verification and recovery emails through HTTPS.

The Android app and website share this backend. Google Drive consent is requested by each client from the signed-in Google account; the backend does not grant it.

## Requirements and local setup

- Node.js 18 or later, as specified in `package.json`.
- A reachable MongoDB database and an application database user.
- A Firebase project with Google authentication enabled.
- A Brevo transactional email API key and verified sender.

From this directory, install dependencies, copy `.env.example` to `.env`, supply your own configuration, and start the server:

```sh
npm ci
npm start
```

The default port is 3000. Check `http://localhost:3000/api/health` for service and database status.

## Environment variables

| Variable | Purpose |
| --- | --- |
| `PORT` | HTTP port, default 3000. Render supplies its port. |
| `NODE_ENV` | Use `production` for deployment. Email delivery is mocked only in test mode. |
| `MONGODB_URI` | MongoDB connection string with the database user's credentials. |
| `JWT_SECRET` | Application session signing secret; provide your own deployment value. |
| `FIREBASE_PROJECT_ID` | Firebase project whose Google ID tokens are accepted; defaults to the existing Edutools project. |
| `BREVO_API_KEY` | Server-side Brevo transactional email API key. |
| `EMAIL_FROM` | Verified Brevo sender address. |
| `BACKEND_URL` | Public backend URL for email action links when `RENDER_EXTERNAL_URL` is unavailable. |
| `FRONTEND_URL` | Companion website address checked by the backend dashboard. |

Keep secrets in local environment files or the deployment provider's settings, not in the website, Flutter source, README, or APK.

## Render and MongoDB

The repository's `render.yaml` configures `backend/` as the service root and `node server.js` as its start command. Supply the environment variables in Render.

For MongoDB Atlas, allow the Render service's outbound IP ranges in the project's IP access list and verify the database user's credentials. Restart after configuration changes. Successful database status should include:

```json
{
  "database": {
    "connected": true,
    "configured": true
  }
}
```

The top-level service status can be healthy while MongoDB is disconnected, so inspect `database.connected`. Google registration returns a retry message when durable storage is unavailable, rather than treating an existing user as unregistered.

## Main API areas

| Route | Purpose |
| --- | --- |
| `GET /api/health` | Service and database status. |
| `POST /api/auth/google-session` | Validate a Firebase Google ID token, resolve a registered profile, or request registration details. |
| `/api/auth/*` | Email verification, password sign-in, password setup, and recovery. |
| `GET/POST /api/student/sync` | Read/write account routine classes and date ranges. |
| `/api/calendar/*` | Academic calendar sync and global calendar data. |
| `POST /api/upload` | Upload handling with the existing size and format restrictions. |

The Google session route takes a Firebase ID token, not a Drive access token. Registered profiles are stored by Firebase identity and email; complete legacy routine profiles can be recovered into registration records.

## Tests and documentation

Install dependencies before running:

```sh
node --test tests/google_session.test.js tests/registration_repository.test.js tests/db_reconnect.test.js tests/email_service.test.js tests/cross_platform_sync.test.js
node --test tests/section_planner.test.js
```

Section Planner tests also read shared assets and the web helper from the repository root.

- [Product overview and Android installation](../README.md)
- [Email setup](../docs/EMAIL_SETUP.md)
- [Routine synchronization](../docs/ROUTINE_SYNC.md)
- [Registration recovery](../docs/REGISTRATION_RECOVERY.md)
- [Section Planner](../docs/SECTION_PLANNER.md)
