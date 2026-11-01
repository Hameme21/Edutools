const { test, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { createRequire } = require('node:module');
const { sendEmail, getEmailStatus } = require('../services/email_service');

const originalEnv = { ...process.env };
afterEach(() => { process.env = { ...originalEnv }; });

function configure() {
  process.env.BREVO_API_KEY = 'fake_brevo_test_key';
  process.env.EMAIL_FROM = 'noreply@verified.example';
}
const mail = {
  from: { name: 'Edutools', email: 'noreply@verified.example' }, to: 'student@bscse.uiu.ac.bd',
  replyTo: 'noreply@verified.example', subject: 'Verify', text: 'Click link', html: '<a>Verify</a>',
};
const accepted = () => ({ ok: true, status: 201, json: async () => ({ messageId: 'email-123' }) });

test('missing configuration fails before any network request', async () => {
  delete process.env.BREVO_API_KEY;
  delete process.env.EMAIL_FROM;
  assert.equal(getEmailStatus(), 'NOT_CONFIGURED');
  await assert.rejects(sendEmail(mail, { fetchImpl: () => assert.fail('network called') }), /requires BREVO_API_KEY/);
});

test('sends the expected authenticated HTTPS payload and returns the provider ID', async () => {
  configure();
  assert.equal(getEmailStatus(), 'CONFIGURED');
  const result = await sendEmail(mail, { fetchImpl: async (url, options) => {
    assert.equal(url, 'https://api.brevo.com/v3/smtp/email');
    assert.equal(options.method, 'POST');
    assert.equal(options.headers['api-key'], 'fake_brevo_test_key');
    assert.equal(options.headers.Authorization, undefined);
    assert.deepEqual(JSON.parse(options.body), {
      sender: mail.from, to: [{ email: mail.to }], replyTo: { email: mail.replyTo },
      subject: mail.subject, htmlContent: mail.html,
    });
    return accepted();
  } });
  assert.equal(result.messageId, 'email-123');
});

test('provider rejection and malformed success cannot report success', async () => {
  configure();
  for (const status of [401, 403, 429, 500, 200]) {
    await assert.rejects(sendEmail(mail, { fetchImpl: async () => ({
      ok: status === 200, status, json: async () => ({ message: 'sensitive provider details' }),
    }) }), error => error.message.includes(`HTTP ${status}`) && !error.message.includes('sensitive'));
  }
});

test('plain text fallback and multiple recipients use Brevo fields', async () => {
  configure();
  await sendEmail({ ...mail, html: undefined, replyTo: undefined, to: [mail.to, 'other@bscse.uiu.ac.bd'] }, {
    fetchImpl: async (_url, options) => {
      const payload = JSON.parse(options.body);
      assert.equal(payload.textContent, mail.text);
      assert.equal(payload.htmlContent, undefined);
      assert.equal(payload.replyTo, undefined);
      assert.deepEqual(payload.to, [{ email: mail.to }, { email: 'other@bscse.uiu.ac.bd' }]);
      return accepted();
    },
  });
});

test('a stalled HTTPS request is aborted', async () => {
  configure();
  await assert.rejects(sendEmail(mail, {
    timeoutMs: 5,
    fetchImpl: async (_url, { signal }) => new Promise((_resolve, reject) => {
      signal.addEventListener('abort', () => reject(new Error('aborted')), { once: true });
    }),
  }), /timed out/);
});

test('network failures propagate instead of reporting email success', async () => {
  configure();
  await assert.rejects(sendEmail(mail, { fetchImpl: async () => { throw new Error('network unavailable'); } }), /network unavailable/);
});

// Exercise the real auth module with isolated persistence and mocked HTTPS only.
// This avoids touching registered students or sending mail when run in a checkout.
function loadAuth(fetchImpl) {
  const filename = path.resolve(__dirname, '../services/auth_service.js');
  const localRequire = createRequire(filename);
  const module = { exports: {} };
  vm.runInNewContext(fs.readFileSync(filename, 'utf8'), {
    module, exports: module.exports, __dirname: path.dirname(filename),
    require: name => {
      if (name === 'fs') return { existsSync: () => false, mkdirSync() {}, writeFileSync() {} };
      if (name === 'dotenv') return { config() {} };
      if (name === './email_service') return { sendEmail: mail => sendEmail(mail, { fetchImpl }), getEmailStatus };
      return localRequire(name);
    },
    process, console: { log() {}, warn() {}, error() {} },
    setTimeout: (...args) => setTimeout(...args).unref(), Buffer,
  }, { filename });
  return module.exports;
}

test('production verification link keeps its URL, expiry and verification behavior', async () => {
  configure();
  process.env.NODE_ENV = 'production';
  delete process.env.RENDER_EXTERNAL_URL;
  process.env.BACKEND_URL = 'https://backend.example';
  let payload;
  const auth = loadAuth(async (_url, options) => { payload = JSON.parse(options.body); return accepted(); });
  // Previously this real-looking name silently bypassed SMTP in production.
  const email = 'john.doe@bscse.uiu.ac.bd';
  const result = await auth.requestEmailVerification(email, 'Student');
  assert.equal(result.success, true);
  assert.equal(result.expiresInSeconds, 900);
  assert.equal(payload.to[0].email, email);
  const url = new URL(payload.htmlContent.match(/https:\/\/backend\.example\/api\/auth\/verify-email\?token=[a-f0-9]+/)[0]);
  const token = url.searchParams.get('token');
  assert.equal(auth.verifyEmailToken(token).success, true);
  assert.equal(auth.studentStore.get(email).emailVerified, true);
  assert.equal(auth.verifyEmailToken('invalid-token').success, false);
});

test('verification provider failure rejects the request and invalidates the pending link', async () => {
  configure();
  process.env.NODE_ENV = 'production';
  let token;
  const auth = loadAuth(async (_url, options) => {
    token = JSON.parse(options.body).htmlContent.match(/token=([a-f0-9]+)/)[1];
    return { ok: false, status: 403, json: async () => ({}) };
  });
  await assert.rejects(auth.requestEmailVerification('student@bscse.uiu.ac.bd', 'Student'), /Failed to send verification email/);
  assert.equal(auth.verifyEmailToken(token).success, false);
});

test('OTP and password reset use the same HTTPS sender', async () => {
  configure();
  process.env.NODE_ENV = 'production';
  const messages = [];
  const auth = loadAuth(async (_url, options) => { messages.push(JSON.parse(options.body)); return accepted(); });
  const email = 'student@bscse.uiu.ac.bd';
  auth.studentStore.set(email, { email, passwordHash: 'fixture' });
  await auth.requestOtp(email);
  await auth.requestPasswordReset(email);
  assert.equal(messages.length, 2);
  assert.match(messages[0].htmlContent, /\b\d{6}\b/);
  assert.match(messages[1].htmlContent, /\/api\/auth\/reset-password\?token=/);
});
