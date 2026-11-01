const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
process.env.NODE_ENV = 'test';
const app = require('../server');
let server, base;
before(async () => {
  server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => new Promise(resolve => { server.closeAllConnections(); server.close(resolve); }));
async function write(body) {
  return fetch(`${base}/api/student/sync`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
}
async function read(email) {
  return (await fetch(`${base}/api/student/sync?email=${encodeURIComponent(email)}`)).json();
}
const fixture = { id: 'C1', subject: 'Algorithms', courseCode: 'CSE1', dayOfWeek: 1, startTime: '09:00', endTime: '10:30', room: '101', instructor: 'Teacher' };
const range = { startDate: '2026-11-01', endDate: '2026-12-01' };
function webClient(email, fetchImpl = fetch) {
  const source = fs.readFileSync(path.resolve(__dirname, '../../index.html'), 'utf8');
  const start = source.indexOf('let routineSyncInFlight = null;');
  const end = source.indexOf('\nfunction renderNextMilestone()', start);
  assert.ok(start > 0 && end > start);
  const context = vm.createContext({
    state: { student: { email }, classes: [], routineRange: null },
    fetch: fetchImpl, AbortController, setTimeout, clearTimeout, console,
    getApiBaseUrl: () => base, renderAll() {}, saveStudentSession() {}, showToast() {},
    localStorage: (() => { const values = new Map(); return {
      setItem: (key, value) => values.set(key, value),
      getItem: key => values.get(key) || null,
      removeItem: key => values.delete(key),
    }; })(),
  });
  vm.runInContext(source.slice(start, end), context);
  return context;
}

test('mobile writes are pulled by web using the same normalized email', async () => {
  await write({ email: 'SYNC-A@EXAMPLE.COM', student: { email: 'sync-a@example.com' }, classes: [fixture], routineRange: range });
  const web = webClient('sync-a@example.com');
  assert.equal(await web.syncStudentWithServer(false), true);
  assert.deepEqual(JSON.parse(JSON.stringify(web.state.classes)), [fixture]);
  assert.deepEqual(JSON.parse(JSON.stringify(web.state.routineRange)), range);
});

test('web edits, date ranges and deletion of the last class reach the mobile snapshot', async () => {
  const web = webClient('sync-b@example.com');
  web.state.classes = [{ ...fixture, room: '202', endTime: '11:00' }];
  web.state.routineRange = range;
  assert.equal(await web.syncStudentWithServer(true), true);
  assert.equal((await read('sync-b@example.com')).classes[0].room, '202');
  web.state.classes = [];
  web.state.routineRange = null;
  assert.equal(await web.syncStudentWithServer(true), true);
  const result = await read('sync-b@example.com');
  assert.equal(result.hasSchedule, true);
  assert.deepEqual(result.classes, []);
  assert.equal(result.routineRange, null);
});

test('missing and empty schedules differ, and another account cannot supply a routine', async () => {
  const missing = await read('sync-never-written@example.com');
  assert.equal(missing.hasSchedule, false);
  assert.deepEqual(missing.classes, []);
  const web = webClient('sync-never-written@example.com');
  await web.syncStudentWithServer(false);
  assert.equal(web.state.classes.length, 0);
});

test('a malformed write cannot erase the saved routine or date range', async () => {
  await write({ email: 'sync-c@example.com', classes: [fixture], routineRange: range });
  assert.equal((await write({ email: 'sync-c@example.com' })).status, 400);
  await write({ email: 'sync-c@example.com', classes: [fixture] });
  assert.deepEqual((await read('sync-c@example.com')).routineRange, range);
});

test('an edit made during a web pull is uploaded instead of overwritten', async () => {
  let release;
  const gate = new Promise(resolve => { release = resolve; });
  let written;
  const web = webClient('sync-d@example.com', async (_url, options) => {
    if (options.method === 'POST') {
      written = JSON.parse(options.body);
      return { ok: true, json: async () => ({ success: true }) };
    }
    await gate;
    return { ok: true, json: async () => ({ success: true, hasSchedule: true, classes: [fixture] }) };
  });
  const pulling = web.syncStudentWithServer(false);
  web.state.classes = [{ ...fixture, room: 'Latest edit' }];
  const pushing = web.syncStudentWithServer(true);
  release();
  await Promise.all([pulling, pushing]);
  assert.equal(written.classes[0].room, 'Latest edit');
  assert.equal(web.state.classes[0].room, 'Latest edit');
});

test('web rejects failed HTTP responses without replacing the local routine', async () => {
  const web = webClient('sync-e@example.com', async () => ({ ok: false, json: async () => ({ success: false }) }));
  web.state.classes = [fixture];
  assert.equal(await web.syncStudentWithServer(true), false);
  assert.equal(web.state.classes.length, 1);
});

test('the existing website routine survives a legacy empty cloud snapshot', async () => {
  await write({ email: 'sync-migration@example.com', classes: [] });
  const web = webClient('sync-migration@example.com');
  web.state.classes = [fixture];
  assert.equal(await web.syncStudentWithServer(false), true);
  assert.equal(web.state.classes.length, 1);
  const saved = await read('sync-migration@example.com');
  assert.equal(saved.syncVersion, 1);
  assert.equal(saved.classes.length, 1);
});
