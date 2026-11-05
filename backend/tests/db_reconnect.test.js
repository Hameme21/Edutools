const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
test('database reconnects after a previously successful connection drops', async () => {
  let attempts = 0;
  const mongoose = { connection:{readyState:0}, connect:async()=>{attempts++;mongoose.connection.readyState=1;} };
  const module = { exports:{} };
  vm.runInNewContext(fs.readFileSync(path.resolve(__dirname,'../db.js'),'utf8'), {
    module, __dirname:path.resolve(__dirname,'..'), process:{env:{}}, console:{log(){},error(){}},
    require:name=>name==='mongoose'?mongoose:name==='dotenv'?{config(){}}:require(name),
  });
  assert.equal(await module.exports.connectDB(), true);
  mongoose.connection.readyState=0;
  assert.equal(await module.exports.connectDB(), true);
  assert.equal(attempts, 2);
});
