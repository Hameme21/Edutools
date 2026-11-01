# Verification email setup (Brevo HTTPS API)

Verification URLs, tokens, expiration, registration, sign-in and polling still use the existing backend. OTP and password-reset messages use the same HTTPS sender. Firebase SMTP configuration is not used.

## Setup without your own domain

1. Create a Brevo account at https://www.brevo.com/ and complete the account setup. If transactional sending is not activated, follow Brevo's activation instructions or contact their support.
2. Open Settings > Senders, Domains, IPs > Senders. Add a sender named `Edutools` using an email inbox you control, such as your Gmail address. Complete the verification code sent to that inbox. Use this exact verified email for `EMAIL_FROM`; do not invent an address such as `noreply@edutools.com` if you do not own it.
3. In Brevo's SMTP & API settings, create an **API key**, not an SMTP key. Store it only as `BREVO_API_KEY` in the Render service's Environment settings. Do not paste it into chat or commit it to the repository.
4. In Render, set `EMAIL_FROM` to your verified sender email. Keep `NODE_ENV=production`, and preserve the existing `JWT_SECRET` and `MONGODB_URI`. Remove the obsolete `RESEND_API_KEY`, `EMAIL_USER`, `EMAIL_PASS` and `SMTP_*` settings. Deploy the updated backend.
5. Request verification for a real UIU email address. Check Brevo's Transactional email logs for acceptance, delivery, bounces or account restrictions. Check the recipient inbox/spam folder, click the link, and confirm the app completes verification.

Brevo currently temporarily replaces free-email sender addresses (including Gmail) with an address on its `brevosend.com` domain to meet authentication requirements. Recipients may see this replacement address. This behavior is managed by Brevo and can change; check the account's current restrictions. A domain you own and authenticate is the longer-term setup for consistent branding and deliverability.

## Configuration and checks

- `BREVO_API_KEY`: the API key from your Brevo account.
- `EMAIL_FROM`: the sender email you verified in Brevo, as a plain email address.
- `BACKEND_URL`: the public HTTPS backend origin when hosting outside Render. Render supplies `RENDER_EXTERNAL_URL`, which takes precedence, for verification links.
- For local development, copy `backend/.env.example` to `backend/.env` and fill in the values. Never put the API key in Flutter or browser code.
- The backend dashboard displays `CONFIGURED` when the two email settings exist. This checks local configuration only; it does not authenticate the key or confirm delivery.
- Run `npm run test:email` inside `backend` for mocked HTTPS and auth-flow checks. No real emails are sent. Only `NODE_ENV=test` bypasses sending.

The API is called over HTTPS port 443, despite `smtp` appearing in Brevo's endpoint path. No SMTP connection is opened. Requests abort after 20 seconds and are not automatically retried, avoiding duplicate messages from uncertain network responses. API acceptance does not guarantee inbox delivery.

Existing verification tokens remain in process memory, so backend restarts can still invalidate pending links. Persistent token storage is a separate change.

Revoke the previously exposed Resend API key and old mail password at their providers. Removing them from environment variables or files does not revoke them.

References:
- https://developers.brevo.com/reference/send-transac-email
- https://help.brevo.com/hc/en-us/articles/208836149-Create-a-new-sender-From-name-and-From-email
- https://help.brevo.com/hc/en-us/articles/16045394674066-Troubleshooting-Domain-authentication
