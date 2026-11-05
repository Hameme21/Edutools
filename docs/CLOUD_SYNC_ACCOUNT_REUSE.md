# Cloud Sync uses the signed-in Google account

The extra account picker came from starting a new Google sign-in inside the Android Drive-sync method. The website also opened a Google reauthentication popup without a login hint whenever its in-memory Drive token was missing.

## Updated behavior

- Android retains the identity returned by explicit Google sign-in. After an app restart it can use the restored Firebase Google provider identity or its saved Google identity metadata. Sync does not call `authenticate` or `attemptLightweightAuthentication`.
- Android requests existing Drive authorization first without UI, passing both the known Google user ID and email. Only when Drive permission is missing does it ask for consent, still bound to that same account.
- The website passes `login_hint` with the signed-in email and does not request account selection. Valid Drive tokens are reused in memory and in that tab's session storage, with a conservative 45-minute lifetime.
- Tokens are associated with an email. A different account's token is not reused. Logout clears cached authorization, and rejected or expired tokens are discarded or renewed.
- Only `https://www.googleapis.com/auth/drive.file` is requested. This grants access to the app's routine files, not the Gmail inbox or unrestricted access to all Drive files.
- The existing routine-file behavior is unchanged: an existing `educal_sync_data.json` is read and applied; a missing routine file is created from the local routine.

Google sign-in and Google Drive permission are separate. The first consent prompt for Drive must still be approved by the user. Google can also require fresh consent or login if the grant is revoked, the account is removed, or the Google session expires. The app cannot bypass that approval.

## Deploy

1. Deploy the updated root `index.html` to the website.
2. Install APK 1.1.7 build 21 over the existing app.
3. Press Cloud Sync while signed into the intended account. Approve access to the app's Drive files if Google has not already granted it.
4. Press Cloud Sync again and check that the existing grant is reused.

No backend or Firebase verification setting changes are required for this update. The Google Drive API and the existing OAuth client must remain enabled/configured as before.

Verification: regression tests cover cached and restored identities, existing grants, first-time consent for a bound account, token expiry, mismatched accounts, website reloads and the existing routine-file rules. APK compilation verifies the Android build. Live OAuth consent still depends on the user's account and must be checked on the installed app/site.

References:
- https://firebase.google.com/docs/reference/js/v8/firebase.auth.GoogleAuthProvider
- https://developers.google.com/workspace/drive/api/guides/api-specific-auth
