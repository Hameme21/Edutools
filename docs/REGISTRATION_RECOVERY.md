# Repeated Google registration prompt

The previous Google-session endpoint looked only in the process cache and the new RegisteredStudent collection. Older releases saved some completed student profiles with StudentSchedule instead. It could also report a completed registration while MongoDB was disconnected, leaving only process memory and a temporary local JSON file.

The backend now:
- Looks up persisted registrations by the stable Firebase user ID, with email fallback for older records.
- Recovers a complete matching profile from StudentSchedule and writes it into RegisteredStudent.
- Waits for the database write before putting a new registration into the cache or issuing an app session.
- Returns HTTP 503 with `REGISTRATION_STORE_UNAVAILABLE` when the registration database cannot be checked or written. An unavailable database is not reported as an unregistered user.
- Retries a dropped database connection and loads local `.env` settings before selecting the database URI.
- Reports database connection state in `/api/health` without exposing the URI or credentials.

Deploy the updated Node backend to Render. This is a backend-only fix: no new APK, website update, or Firebase verification setting is required. Then open:

https://edutools-y4xy.onrender.com/api/health

Check `database.connected` is `true`. `database.configured: true` only means MONGODB_URI is present; it does not prove that MongoDB is reachable. If disconnected, inspect Render's MongoDB error logs and the database user's access/network configuration. Do not share the URI or password.

Try Google sign-in again. A saved registration or a complete matching legacy profile should bypass the registration form. If the old registration was already lost and no completed profile exists in persistent storage, its missing details cannot be reconstructed automatically; restore that profile once after the database is healthy.

Checks:
```
node --test tests/google_session.test.js tests/registration_repository.test.js tests/db_reconnect.test.js tests/email_service.test.js tests/cross_platform_sync.test.js
```
Tests simulate cache loss, completed legacy profiles, failed writes, database outages, reconnection and stable-identity lookup without modifying production data. A live Render/MongoDB check is still required after deployment.
