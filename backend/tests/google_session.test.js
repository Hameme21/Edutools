const { test } = require('node:test');
const assert = require('node:assert/strict');
const { generateKeyPairSync } = require('node:crypto');
const jwt = require('jsonwebtoken');
process.env.NODE_ENV = 'test';
const { authenticate: realAuthenticate, verifyGoogleIdentity, DEPARTMENTS } = require('../services/google_session_service');
const rows = new Map();
const store = {
  find: async identity => rows.get(identity.uid) || null,
  save: async (identity, profile) => rows.set(identity.uid, { ...profile }),
};
const authenticate = (idToken, profile, verify) => realAuthenticate(idToken, profile, verify, store);
const auth = require('../services/auth_service');
// Registration tests must not add fixture accounts to the checkout's data file.
auth.saveRegisteredStudents = () => {};
const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const now = Math.floor(Date.now() / 1000);
function sign(overrides = {}) {
  return jwt.sign({ sub: 'google-user', email: 'oauth-tests@example.com', email_verified: true, auth_time: now,
    firebase: { sign_in_provider: 'google.com' }, ...overrides }, privateKey,
  { algorithm: 'RS256', keyid: 'test-key', audience: 'edutools-e2558', issuer: 'https://securetoken.google.com/edutools-e2558', expiresIn: '1h' });
}
const certificates = async () => ({ ok: true, headers: { get: () => 'max-age=300' }, json: async () => ({ 'test-key': publicKey.export({ type: 'spki', format: 'pem' }) }) });
test('verifies a signed Firebase Google token and rejects forged or unverified identity', async () => {
  assert.equal((await verifyGoogleIdentity(sign(), certificates)).email, 'oauth-tests@example.com');
  await assert.rejects(verifyGoogleIdentity(sign({ email_verified: false }), certificates));
  await assert.rejects(verifyGoogleIdentity(sign({ firebase: { sign_in_provider: 'password' } }), certificates));
  await assert.rejects(verifyGoogleIdentity(sign({ auth_time: now + 1000 }), certificates));
  await assert.rejects(verifyGoogleIdentity('invalid', certificates));
  const forged = jwt.sign({ email: 'oauth-tests@example.com' }, 'not-google');
  await assert.rejects(verifyGoogleIdentity(forged, certificates));
});
test('unknown Google user must register before receiving an app session', async () => {
  auth.studentStore.delete('oauth-tests@example.com');
  const result = await authenticate(sign(), undefined, token => verifyGoogleIdentity(token, certificates));
  assert.equal(result.requiresRegistration, true);
  assert.equal(result.token, undefined);
  assert.equal(auth.studentStore.has('oauth-tests@example.com'), false);
});
test('all seven departments are accepted and invalid departments are rejected', async () => {
  assert.equal(DEPARTMENTS.length, 7);
  await assert.rejects(authenticate(sign(), { fullName: 'Student', studentId: '1', department: 'INVALID' }, token => verifyGoogleIdentity(token, certificates)), /department/);
  for (const department of DEPARTMENTS) {
    const email = `${department.toLowerCase()}-oauth@example.com`;
    auth.studentStore.delete(email);
    const verify = async () => ({ email, uid: department, name: 'Student' });
    const result = await authenticate('test', { fullName: 'Student', studentId: '123', department }, verify);
    assert.equal(result.requiresRegistration, false);
    assert.equal(result.student.department, department);
    assert.ok(result.token);
  }
});
test('returning registered user receives a session without another registration or email link', async () => {
  const verify = async () => ({ email: 'cse-oauth@example.com', uid: 'CSE', name: 'Student' });
  const result = await authenticate('test', undefined, verify);
  assert.equal(result.requiresRegistration, false);
  assert.equal(result.student.studentId, '123');
  assert.equal(result.student.passwordHash, undefined);
  assert.ok(result.token);
});

test('registration survives clearing the server memory cache', async () => {
  const verify = async () => ({ email: 'cse-oauth@example.com', uid: 'CSE', name: 'Student' });
  auth.studentStore.delete('cse-oauth@example.com');
  const result = await authenticate('test', undefined, verify);
  assert.equal(result.requiresRegistration, false);
  assert.equal(result.student.department, 'CSE');
});

test('database lookup failure cannot classify a registered user as new', async () => {
  const verify = async () => ({ email: 'unavailable-oauth@example.com', uid: 'unavailable', name: 'Student' });
  const unavailable = { find: async () => { throw new Error('Database offline'); }, save: async () => assert.fail('unexpected save') };
  await assert.rejects(realAuthenticate('test', undefined, verify, unavailable), error => error.status === 503 && error.code === 'REGISTRATION_STORE_UNAVAILABLE');
  assert.equal(auth.studentStore.has('unavailable-oauth@example.com'), false);
});

test('failed persistence cannot mark a new registration complete in memory', async () => {
  const verify = async () => ({ email: 'write-failure@example.com', uid: 'write-failure', name: 'Student' });
  const unavailable = { find: async () => null, save: async () => { throw new Error('Write failed'); } };
  await assert.rejects(realAuthenticate('test', { fullName:'Student', studentId:'1', department:'DS' }, verify, unavailable), error => error.status === 503);
  assert.equal(auth.studentStore.has('write-failure@example.com'), false);
});

test('same Firebase identity restores its registered profile after an email change', async () => {
  rows.set('renamed-google-user', { id:'1', email:'old-oauth@example.com', fullName:'Student', studentId:'5', department:'CE', registrationComplete:true });
  const verify = async () => ({ email:'new-oauth@example.com', uid:'renamed-google-user', name:'Student' });
  const result = await authenticate('test', undefined, verify);
  assert.equal(result.requiresRegistration, false);
  assert.equal(result.student.email, 'new-oauth@example.com');
  assert.equal(result.student.studentId, '5');
});
