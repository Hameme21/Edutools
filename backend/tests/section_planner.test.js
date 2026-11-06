const {test} = require('node:test');
const assert = require('node:assert/strict');
const planner = require('../../section_planner');
const {offerings} = require('../../sample_data/fall_2026_sections.json');
const catalog = require('../../sample_data/course_catalog.json');
test('PDF import contains every row and preserves exact morning, noon and lab times', () => {
  assert.equal(offerings.length, 791);
  assert.deepEqual(offerings.map(s => s.sourceRow), Array.from({length:791}, (_,i) => i+1));
  assert.equal(offerings.flatMap(s => s.meetings).length, 1296);
  assert.equal(offerings[0].meetings[0].startTime, '08:30');
  assert.equal(offerings[1].meetings[0].startTime, '09:51');
  assert.equal(offerings[5].meetings[0].endTime, '13:50');
  assert.deepEqual(offerings[196].meetings, [{dayOfWeek:3,startTime:'11:11',endTime:'13:40',room:'827'}]);
  assert.equal(offerings[267].meetings[0].startTime, '14:00');
  for (const section of offerings) for (const m of section.meetings) {
    assert.ok(m.dayOfWeek >= 1 && m.dayOfWeek <= 7);
    assert.ok(m.startTime < m.endTime);
  }
  assert.ok(offerings.some(s => s.facultyName === 'To be announced'));
});
test('clashes require overlapping times on the same day; touching boundaries are allowed', () => {
  const a = {dayOfWeek:7,startTime:'12:30',endTime:'13:50'};
  assert.equal(planner.overlaps(a, {...a,startTime:'13:50',endTime:'15:10'}), false);
  assert.equal(planner.overlaps(a, {...a,startTime:'13:49',endTime:'15:10'}), true);
  assert.equal(planner.overlaps(a, {...a,dayOfWeek:1}), false);
});
test('backup sections are alternatives; different active courses and configured classes are checked', () => {
  const a = offerings[0], backup = {...a,id:'backup',section:'B'}, other = {...a,id:'other',courseCode:'CSE 1111'};
  assert.equal(planner.clashes(backup,[a],[]).length, 0);
  assert.equal(planner.clashes(other,[a],[]).length, 2);
  assert.equal(planner.clashes(a,[],[{...a.meetings[0],courseCode:'MATH 1151'}]).length, 1);
});
test('applying uses only active sections, replaces their previous meetings and preserves other courses', () => {
  const a = offerings[0];
  const other = {id:'keep',courseCode:'MATH 1151',dayOfWeek:5,startTime:'08:30',endTime:'09:50'};
  const result = planner.applySections([a], [{...a.meetings[0],courseCode:'ACT-2111'},other]);
  assert.equal(result.length,3); assert.ok(result.includes(other));
  assert.throws(() => planner.applySections([a,a],[]));
  assert.equal(planner.resolveCode('Database Management Systems',catalog),'CSE 3521');
  assert.equal(planner.resolveCode('Made up course',catalog),null);
});
test('unified preview keeps conflicting active meetings visible while apply remains blocked', () => {
  const a=offerings[0], other={...a,id:'other-course',courseCode:'CSE 1111'};
  const unified=planner.unifiedMeetings([a,other],[]);
  assert.equal(unified.length,4);
  assert.ok(planner.overlaps(unified[0],unified[2]));
  assert.throws(()=>planner.applySections([a,other],[]));
  assert.equal(planner.minutes('09:51'),591);
  assert.equal(planner.minutes('13:40'),820);
});
test('section search accepts faculty full names and initials without case sensitivity',()=>{
  assert.equal(planner.matchesSectionFaculty(offerings[1],'Shakila Aziz'),true);
  assert.equal(planner.matchesSectionFaculty(offerings[1],'sHaZ'),true);
  assert.equal(planner.matchesSectionFaculty(offerings[1],'B'),true);
  assert.equal(planner.matchesSectionFaculty(offerings[0],'ShAz'),false);
});
test('semester rollover clears old choices once and preserves new selection preparation',()=>{
  const range={endDate:'2026-12-31'};
  assert.equal(planner.expiredPlannerEnd(range,new Date(2026,11,31,23,59)),null);
  const end=planner.expiredPlannerEnd(range,new Date(2027,0,1,1));
  assert.equal(end,'2026-12-31');
  const old={selected:['F26-1'],primary:{ACT2111:'F26-1'}};
  const reset=planner.rolloverSectionDraft(old,end,new Date(2027,0,1,1));
  assert.deepEqual(reset.selected,[]);
  const next={...reset,selected:['F26-2'],primary:{ACT2111:'F26-2'}};
  assert.deepEqual(planner.rolloverSectionDraft(next,end,new Date(2027,0,2)).selected,['F26-2']);
  const fresh={...old,savedAtMs:new Date(2027,0,1,0,1).getTime()};
  assert.deepEqual(planner.rolloverSectionDraft(fresh,end,new Date(2027,0,2)).selected,['F26-1']);
});
test('faculty is assigned by course and section; custom corrections remain editable',()=>{
  const cls={courseCode:'ACT-2111',subject:'Accounting · Section B',instructor:''};
  const filled=planner.fillSectionInstructor(cls,offerings);
  assert.equal(filled.instructor,'Shakila Aziz');assert.equal(filled.section,'B');
  assert.equal(planner.fillSectionInstructor({...filled,instructor:'Corrected instructor'},offerings).instructor,'Corrected instructor');
  assert.equal(planner.assignedInstructor('ACT 2111','NOPE',offerings),null);
  assert.equal(planner.applySections([offerings[1]],[])[0].instructor,'Shakila Aziz');
});
