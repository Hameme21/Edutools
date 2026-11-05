const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.resolve(__dirname, '../../index.html'), 'utf8');
const start = source.indexOf('async function syncWithGoogleDriveWeb(');
const end = source.indexOf('let routineSyncInFlight', start);
function client(files, remote, failList = false, setup) {
  const requests = [];
  const context = vm.createContext({
    state: { student: { email: 'student@example.com', token: 'private-session-token' }, classes: [{ id: 'LOCAL' }], routineRange: null, googleAccessToken: 'fake-google-access', googleAccessTokenEmail: 'student@example.com', googleAccessTokenExpiresAt: Date.now() + 600000 },
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
  if (setup) setup(context);
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

function memoryStorage() {
  const values = new Map();
  return { getItem: key => values.get(key) || null, setItem: (key, value) => values.set(key, value), removeItem: key => values.delete(key) };
}
function googleAuthorization(context, resultEmail = 'student@example.com') {
  let popups = 0;
  let parameters;
  let scopes;
  class Provider {
    constructor() { scopes = []; }
    addScope(scope) { scopes.push(scope); }
    setCustomParameters(value) { parameters = value; }
  }
  const popup = async () => { popups++; return { user: { email: resultEmail }, credential: { accessToken: 'granted-drive-token' } }; };
  const user = { email: 'student@example.com', reauthenticateWithPopup: popup };
  context.firebase = { auth: Object.assign(() => ({ currentUser: user, signInWithPopup: popup }), { GoogleAuthProvider: Provider }) };
  return { get popups() { return popups; }, get parameters() { return parameters; }, get scopes() { return scopes; } };
}
test('first website Drive grant uses a login hint for the signed-in account and is reused', async () => {
  let authorization;
  const { context } = client([{id:'routine'}], {classes:[]}, false, ctx => {
    ctx.state.googleAccessToken = null;
    ctx.sessionStorage = memoryStorage();
    authorization = googleAuthorization(ctx);
  });
  assert.equal(await context.syncWithGoogleDriveWeb(), true);
  assert.equal(await context.syncWithGoogleDriveWeb(), true);
  assert.equal(authorization.popups, 1);
  assert.equal(authorization.parameters.login_hint, 'student@example.com');
  assert.equal(authorization.parameters.prompt, '');
  assert.deepEqual(authorization.scopes, ['https://www.googleapis.com/auth/drive.file']);
});
test('website reload reuses a valid same-account tab token without another Google popup', async () => {
  const storage = memoryStorage();
  storage.setItem('edutools_drive_authorization', JSON.stringify({ email:'student@example.com', accessToken:'existing-tab-token', expiresAt:Date.now()+600000 }));
  let authorization;
  const { context } = client([{id:'routine'}], {classes:[]}, false, ctx => {
    ctx.state.googleAccessToken = null;
    ctx.sessionStorage = storage;
    authorization = googleAuthorization(ctx);
  });
  assert.equal(await context.syncWithGoogleDriveWeb(), true);
  assert.equal(authorization.popups, 0);
  assert.equal(context.state.googleAccessToken, 'existing-tab-token');
});
test('website never reuses another account token and rejects a mismatched Google response', async () => {
  let authorization;
  const { context, requests } = client([{id:'routine'}], {classes:[]}, false, ctx => {
    ctx.state.googleAccessTokenEmail = 'someone-else@example.com';
    ctx.sessionStorage = memoryStorage();
    authorization = googleAuthorization(ctx, 'someone-else@example.com');
  });
  assert.equal(await context.syncWithGoogleDriveWeb(), false);
  assert.equal(authorization.parameters.login_hint, 'student@example.com');
  assert.equal(requests.length, 0);
  assert.equal(context.state.googleAccessToken, null);
});
test('an expired website grant is renewed for the current account', async () => {
  let authorization;
  const { context } = client([{id:'routine'}], {classes:[]}, false, ctx => {
    ctx.state.googleAccessTokenExpiresAt = Date.now()-1000;
    ctx.sessionStorage = memoryStorage();
    authorization = googleAuthorization(ctx);
  });
  assert.equal(await context.syncWithGoogleDriveWeb(), true);
  assert.equal(authorization.popups, 1);
  context.clearGoogleDriveAuthorization();
  assert.equal(context.state.googleAccessToken, null);
  assert.equal(context.sessionStorage.getItem('edutools_drive_authorization'), null);
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
