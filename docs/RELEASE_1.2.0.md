Edutools 1.2.0

- Improved Google sign-in feedback and registration handling for returning users.
- Added persistent registration recovery, including older complete profiles. Temporary database failures now show a retry message instead of asking users to register again.
- Cloud Sync reuses the signed-in Google identity and requests Drive access for that account when needed.
- Drive Sync restores an existing educal_sync_data.json routine or creates it when missing.
- Improved routine synchronization between Android and the website, including routine date ranges and intentional deletions.
- Registration offers CSE, DS, BBA, CE, EDS, EEE and BSE.
- Android notification permission and separate categories for classes, events, semester fees, exams and holidays.

Android version: 1.2.0 (build 120).

Google may still request consent when Drive permission has not been granted or authorization expires. Registration and cross-device sync require the updated backend and a connected MongoDB database. Notification timing depends on Android permissions and battery settings.
