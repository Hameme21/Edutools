const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const identity = { email:'student@example.com', uid:'stable-firebase-id' };

function repository({ connected = true, reconnect = false, legacy = null, records = [] } = {}) {
  const state = { connected, reconnects:0, records, writes:0 };
  const model = {
    findOne: filter => ({ lean: async () => records.find(row => Object.entries(filter).every(([key, value]) => row[key] === value)) || null }),
    findOneAndUpdate: async (filter, update) => {
      state.writes++;
      let row = records.find(row => Object.entries(filter).every(([key, value]) => row[key] === value));
      if (!row) { row = {_id:`row-${records.length}`}; records.push(row); }
      Object.assign(row, update.$set);
      return row;
    },
  };
  const module = { exports:{} };
  vm.runInNewContext(fs.readFileSync(path.resolve(__dirname, '../services/registration_repository.js'), 'utf8'), {
    module, require: name => {
      if (name === '../db') return { isConnected:()=>state.connected, connectDB:async()=>{state.reconnects++;state.connected=reconnect;} };
      if (name === '../models/RegisteredStudent') return model;
      if (name === '../models/StudentSchedule') return { findOne:()=>({lean:async()=>legacy}) };
      throw new Error(`Unexpected import ${name}`);
    },
  });
  return { ...module.exports, state };
}
test('a completed legacy sync profile is recovered and persisted as a registration', async () => {
  const repo = repository({legacy:{student:{email:identity.email, fullName:'Student Name', studentId:'123', department:'Computer Science & Engineering'}}});
  const profile = await repo.find(identity);
  assert.equal(profile.department, 'CSE');
  assert.equal(profile.registrationComplete, true);
  await repo.save(identity, profile);
  assert.equal(repo.state.records[0].firebaseUid, identity.uid);
  assert.equal(repo.state.records[0].profile.studentId, '123');
});
test('an existing UID-linked registration is preferred over an email-only legacy row', async () => {
  const repo = repository({records:[
    {_id:'current',firebaseUid:identity.uid,email:'previous@example.com',profile:{fullName:'Registered Student',studentId:'1',department:'DS'}},
    {_id:'legacy',email:identity.email,profile:{fullName:'Older Profile',studentId:'2',department:'CSE'}},
  ]});
  assert.equal((await repo.find(identity)).studentId, '1');
});
test('a configured but disconnected database never returns an unknown-user result', async () => {
  const repo = repository({connected:false});
  await assert.rejects(repo.find(identity), error=>error.status===503);
  assert.equal(repo.state.reconnects, 1);
});
test('a dropped database connection is retried before registration lookup', async () => {
  const repo = repository({connected:false,reconnect:true,records:[{email:identity.email,profile:{studentId:'1'}}]});
  assert.equal((await repo.find(identity)).studentId, '1');
  assert.equal(repo.state.reconnects, 1);
});
test('empty, partial and differently-owned sync profiles are not treated as completed registration', async () => {
  for (const student of [null,{email:identity.email},{email:'other@example.com',fullName:'Other',studentId:'2',department:'CSE'}]) {
    assert.equal(await repository({legacy:{student}}).find(identity), null);
  }
});
