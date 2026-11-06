const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.resolve(__dirname, '../../index.html'), 'utf8');
test('new Google user stays behind an opaque registration gate until required details are saved', async () => {
  const nodes = new Map();
  function node(id) {
    if (!nodes.has(id)) {
      const classes = new Set();
      nodes.set(id, { value: '', style: {}, textContent: '', classList: { add: c => classes.add(c), remove: c => classes.delete(c), contains: c => classes.has(c) } });
    }
    return nodes.get(id);
  }
  const context = vm.createContext({
    AbortSignal, document: { getElementById: node }, state: { student: null },
    showAuthGate: () => node('authGate').classList.remove('hidden'),
    hideAuthGate: () => node('authGate').classList.add('hidden'),
    getApiBaseUrl: () => '', saveStudentSession() {}, startCrossPlatformAutoSync() {},
    syncStudentWithServer() {}, renderAll() {}, updateSyncStatusUI() {},
    fetch: async () => ({ ok: true, json: async () => ({ success: true, student: { email: 'student@example.com', fullName: 'Student', studentId: '123', department: 'CSE' }, token: 'app-session' }) }),
  });
  const start = source.indexOf('function completeGoogleSession(');
  const end = source.indexOf('function openEditProfileModal', start);
  vm.runInContext(source.slice(start, end), context);
  context.showGoogleVerifyModal('student@example.com', 'Student', 'verified-google-id-token');
  assert.equal(context.state.student, null);
  assert.equal(node('authGate').classList.contains('hidden'), false);
  assert.equal(node('googleVerifyModal').classList.contains('show'), true);
  assert.equal(node('gvSkipBtn').style.display, 'none');
  assert.equal(node('gvName').value, '');
  await node('gvSaveProfileBtn').onclick();
  assert.equal(context.state.student, null);
  node('gvName').value = 'Student'; node('gvStudentId').value = '123'; node('gvDept').value = 'CSE';
  await node('gvSaveProfileBtn').onclick();
  assert.equal(context.state.student.department, 'CSE');
  assert.equal(node('authGate').classList.contains('hidden'), true);
  assert.match(source, /#googleVerifyModal\s*\{[^}]*background:var\(--bg-main\)/);
});
