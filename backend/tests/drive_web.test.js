const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.resolve(__dirname, '../../index.html'), 'utf8');
const start = source.indexOf('async function syncWithGoogleDriveWeb(');
const end = source.indexOf('let routineSyncInFlight', start);
function client(files, remote, failList = false) {
  const requests = [];
  const context = vm.createContext({
    state: { student: { email: 'student@example.com', token: 'private-session-token' }, classes: [{ id: 'LOCAL' }], routineRange: null, googleAccessToken: 'fake-google-access' },
    AbortSignal, console, showToast() {}, saveStudentSession() {}, renderAll() {},
    syncStudentWithServer: async () => true,
    fetch: async (url, options) => {
      requests.push({ url, options });
      if (failList) return { ok: false, status: 403 };
      if (url.includes('alt=media')) return { ok: true, json: async () => remote };
      if (url.includes('/upload/')) return { ok: true };
      return { ok: true, json: async () => ({ files }) };
    },
  });
  vm.runInContext(source.slice(start, end), context);
  return { context, requests };
}
test('existing routine JSON is applied without uploading or overwriting it', async () => {
  const { context, requests } = client([{ id: 'existing' }], { classes: [{ id: 'REMOTE' }], routineRange: { title: 'Remote dates' } });
  assert.equal(await context.syncWithGoogleDriveWeb(), true);
  assert.equal(context.state.classes[0].id, 'REMOTE');
  assert.equal(context.state.routineRange.title, 'Remote dates');
  assert.equal(requests.some(r => r.options.method === 'POST' || r.options.method === 'PATCH'), false);
});
test('no routine file creates one and does not store the app session token in Drive', async () => {
  const { context, requests } = client([], null);
  assert.equal(await context.syncWithGoogleDriveWeb(), true);
  const upload = requests.find(r => r.url.includes('/upload/'));
  assert.equal(upload.options.method, 'POST');
  assert.ok(upload.options.body.includes('educal_sync_data.json'));
  assert.equal(upload.options.body.includes('private-session-token'), false);
});
test('empty Drive routine clears local classes and lookup failure never creates a file', async () => {
  const empty = client([{ id: 'existing' }], { classes: [], routineRange: null });
  assert.equal(await empty.context.syncWithGoogleDriveWeb(), true);
  assert.equal(empty.context.state.classes.length, 0);
  const denied = client([], null, true);
  assert.equal(await denied.context.syncWithGoogleDriveWeb(), false);
  assert.equal(denied.requests.length, 1);
  assert.equal(denied.context.state.googleAccessToken, null);
});
test('malformed or differently-owned Drive file does not replace the local routine', async () => {
  for (const data of [{ classes: 'broken' }, { classes: [], student: { email: 'someone-else@example.com' } }]) {
    const { context } = client([{ id: 'existing' }], data);
    assert.equal(await context.syncWithGoogleDriveWeb(), false);
    assert.equal(context.state.classes[0].id, 'LOCAL');
  }
});
